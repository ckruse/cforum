module ThreadsHelper
  def hide_read_threads(threads)
    if params[:srt] == 'yes'
      session[:srt] = true
    elsif params[:srt] == 'no'
      session.delete :srt
    end

    if current_user.blank? || @view_all || (uconf('hide_read_threads') != 'yes') ||
       session[:srt] || (controller_path == 'cf_archive')
      return threads
    end

    threads.where('EXISTS(SELECT a.message_id FROM messages a ' \
                  '  LEFT JOIN read_messages b ON a.message_id = b.message_id AND b.user_id = ? ' \
                  '  WHERE thread_id = threads.thread_id AND read_message_id IS NULL AND a.deleted = false) OR ' \
                  'EXISTS(SELECT a.message_id FROM messages AS a ' \
                  '  INNER JOIN interesting_messages USING(message_id) ' \
                  '  WHERE thread_id = threads.thread_id AND interesting_messages.user_id = ? AND deleted = false)',
                  current_user.user_id, current_user.user_id)
  end

  def get_threads(forum, order = 'threads.created_at DESC', user = current_user,
                  with_sticky = false, thread_conditions = {})
    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false

    unless @view_all
      conditions[:deleted] = false
      conditions[:messages] = { deleted: false }
    end

    conditions.merge!(thread_conditions)

    @sticky_threads = nil
    @threads = CfThread
                 .preload(:forum, messages: [:owner, :tags, votes: :voters])
                 .includes(messages: :owner)
                 .where(conditions)

    if with_sticky
      @threads = @threads.where(sticky: false)
      @sticky_threads = CfThread
                          .preload(:forum, messages: [:owner, :tags, votes: :voters])
                          .includes(messages: :owner)
                          .where(conditions)
                          .where(sticky: true)
    end

    if forum
      @threads = @threads.where(forum_id: forum.forum_id)
      @sticky_threads = @sticky_threads.where(forum_id: forum.forum_id) if with_sticky
    elsif !user || !user.admin?
      crits = []
      if user
        crits << 'threads.forum_id IN (SELECT forum_id FROM forums_groups_permissions ' \
                 '  INNER JOIN groups_users USING(group_id) WHERE user_id = ' + user.user_id.to_s + ')'
      end

      additional_perms = if user
                           "', '" + ForumGroupPermission::KNOWN_WRITE + "','" + ForumGroupPermission::KNOWN_READ
                         else
                           ''
                         end

      crits << "threads.forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
               ForumGroupPermission::READ + "','" +
               ForumGroupPermission::WRITE +
               additional_perms + "'))"

      @threads = @threads.where(crits.join(' OR '))
      @sticky_threads = @sticky_threads.where(crits.join(' OR ')) if with_sticky
    end

    @threads = @threads.order(order)
    @sticky_threads = @sticky_threads.order(order) if with_sticky

    @threads = hide_read_threads(@threads)
    @sticky_threads = hide_read_threads(@sticky_threads) if with_sticky

    @threads = leave_out_invisible(@threads)
    @sticky_threads = leave_out_invisible(@sticky_threads) if with_sticky

    [@sticky_threads, @threads]
  end

  def index_threads(with_sticky = true, page = nil, limit = nil, gen_tree = true, only_sql = false)
    forum  = current_forum

    @order = uconf('sort_threads')
    @order = cookies[:cf_order] if cookies[:cf_order].present? && current_user.blank?
    @order = params[:order] if params[:order].present?
    @order = 'ascending' unless %w[ascending descending newest-first].include?(@order)

    if params[:order].present? && current_user.blank?
      cookies[:cf_order] = { value: @order, expires: 1.year.from_now }
    end

    order = case @order
            when 'ascending'
              'threads.created_at ASC'
            when 'newest-first'
              'threads.latest_message DESC'
            else
              'threads.created_at DESC'
            end

    @sticky_threads, @threads = get_threads(forum, order, current_user, with_sticky)

    if params[:only_wo_answer]
      open_threads = CfThread
                       .joins(:messages)
                       .where(archived: false, deleted: false, messages: { deleted: false })
                       .where('threads.forum_id IN (?)', Forum.visible_forums(current_user).select(:forum_id))
                       .where("(messages.flags->>'no-answer-admin' = 'no' OR " \
                              "  (messages.flags->>'no-answer-admin') IS NULL) AND " \
                              "  (messages.flags->>'no-answer' = 'no' OR (messages.flags->>'no-answer') IS NULL)")
                       .group('threads.thread_id')
                       .having('COUNT(*) <= 1')

      @threads = @threads.where(thread_id: open_threads)
      @sticky_threads = @sticky_threads.where(thread_id: open_threads)
    end

    if uconf('page_messages') == 'yes'
      if page.nil?
        @page  = params[:p].to_i
        @page  = 0 if @page.negative?
      elsif page >= 0
        @page = page
      end

      if limit.nil?
        @limit = uconf('pagination').to_i
        @limit = 50 if @limit <= 0
      elsif limit >= 0
        @limit = limit
      end

      @all_threads_count = @threads.count

      if @limit
        @limit -= @sticky_threads.length if with_sticky
        @threads = @threads.limit(@limit)
      end

      @threads = @threads.offset(@limit * @page) if @page
    end

    return @threads.to_sql, @sticky_threads.to_sql if only_sql

    if gen_tree
      @threads.each do |t|
        sort_thread(t)
      end
    end

    if with_sticky
      if gen_tree
        @sticky_threads.each do |t|
          sort_thread(t)
        end
      end

      @threads = @sticky_threads + @threads
    end

    @threads
  end

  def thread_html(thread)
    html = '<article class="thread threadlist'
    html << ' archived' if thread.archived
    html << ' no-archive' if thread.flags['no-archive'] == 'yes'
    html << ' sticky' if thread.sticky
    html << ' ' << thread.attribs['classes'].join(' ') if thread.attribs['classes'].present?
    html << '" id="t' << thread.thread_id.to_s << '">'

    if thread.flags['no-archive'] == 'yes'
      html << '<i class="no-archive-icon" title="' + t('threads.no_archive') + '"> </i>'
    end

    if thread.sticky
      html << '<i class="sticky-icon" title="' + t('threads.is_sticky') + '"> </i>'
    end

    if thread.attribs[:has_interesting]
      html << '<i class="has-interesting-icon" title="' + t('threads.has_interesting') + '"> </i>'
    end

    html << message_header(thread, thread.message, first: true, show_icons: true)

    if thread.message.messages.present? && (thread.attribs['open_state'] != 'closed')
      html << message_tree(thread, thread.message.messages,
                           show_icons: true,
                           hide_repeating_subjects: uconf('hide_subjects_unchanged') == 'yes',
                           hide_repeating_tags: uconf('hide_repeating_tags') == 'yes',
                           parent_subscribed: thread.message.attribs[:is_subscribed])
    end
    html << '</article>'

    html.html_safe
  end

  def save_thread(thread)
    num = 1

    begin
      CfThread.transaction do
        thread.save!
      end
    rescue ActiveRecord::RecordInvalid
      if thread.errors.keys == [:slug]
        thread.slug = CfThread.gen_id(thread, num)
        num += 1
        retry
      end

      raise ActiveRecord::Rollback
    end
  end
end
