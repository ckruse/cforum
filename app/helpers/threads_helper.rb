module ThreadsHelper
  def hide_read_threads(threads)
    if params[:srt] == 'yes'
      session[:srt] = true
    elsif params[:srt] == 'no'
      session.delete :srt
    end

    return threads if current_user.blank? or @view_all or uconf('hide_read_threads') != 'yes' or session[:srt] or controller_path == 'cf_archive'

    threads.where("EXISTS(SELECT a.message_id FROM messages a LEFT JOIN read_messages b ON a.message_id = b.message_id AND b.user_id = ? WHERE thread_id = threads.thread_id AND read_message_id IS NULL AND a.deleted = false) OR EXISTS(SELECT a.message_id FROM messages AS a INNER JOIN interesting_messages USING(message_id) WHERE thread_id = threads.thread_id AND interesting_messages.user_id = ? AND deleted = false)",
                  current_user.user_id, current_user.user_id)
  end

  def get_threads(forum, order = 'threads.created_at DESC', user = current_user, with_sticky = false, thread_conditions = {})
    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false

    unless @view_all
      conditions[:deleted] = false
      conditions[:messages] = {deleted: false}
    end

    conditions.merge!(thread_conditions)

    @sticky_threads = nil
    @threads = CfThread.
               preload(:forum, messages: [:owner, :tags, votes: :voters]).
               includes(messages: :owner).
               where(conditions)

    if with_sticky
      @threads = @threads.where(sticky: false)
      @sticky_threads = CfThread.
                        preload(:forum, messages: [:owner, :tags, votes: :voters]).
                        includes(messages: :owner).
                        where(conditions).
                        where(sticky: true)
    end

    if forum
      @threads = @threads.where(forum_id: forum.forum_id)
      @sticky_threads = @sticky_threads.where(forum_id: forum.forum_id) if with_sticky
    else
      if not user or not user.admin?
        crits = []
        crits << "threads.forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = " + user.user_id.to_s + ")" if user
        crits << "threads.forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
          CfForumGroupPermission::ACCESS_READ + "','" +
          CfForumGroupPermission::ACCESS_WRITE +
          (user ? ("', '" +
                   CfForumGroupPermission::ACCESS_KNOWN_WRITE + "','" +
                   CfForumGroupPermission::ACCESS_KNOWN_READ) : ""
          ) +
          "'))"

        @threads = @threads.where(crits.join(" OR "))
        @sticky_threads = @sticky_threads.where(crits.join(" OR ")) if with_sticky
      end
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
    @order = cookies[:cf_order] if not cookies[:cf_order].blank? and current_user.blank?
    @order = params[:order] unless params[:order].blank?
    @order = 'ascending' unless %w(ascending descending newest-first).include?(@order)

    if not params[:order].blank? and current_user.blank?
      cookies[:cf_order] = {value: @order, expires: 1.year.from_now}
    end

    case @order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end

    @sticky_threads, @threads = get_threads(forum, order, current_user, with_sticky)

    if uconf('page_messages') == 'yes'
      if page.nil?
        @page  = params[:p].to_i
        @page  = 0 if @page < 0
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
      for t in @threads
        sort_thread(t)
      end
    end

    if with_sticky
      if gen_tree
        for t in @sticky_threads
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
    html << ' ' << thread.attribs['classes'].join(' ') unless thread.attribs['classes'].blank?
    html << '" id="t' << thread.thread_id.to_s << '">'

    html << '<i class="no-archive-icon" title="' + t('threads.no_archive') + '"> </i>' if thread.flags['no-archive'] == 'yes'
    html << '<i class="sticky-icon" title="' + t('threads.is_sticky') + '"> </i>' if thread.sticky
    html << '<i class="has-interesting-icon" title="' + t('threads.has_interesting') + '"> </i>' if thread.attribs[:has_interesting]

    html << message_header(thread, thread.message, first: true, show_icons: true)

    if not thread.message.messages.blank? and thread.attribs['open_state'] != 'closed'
      html << message_tree(thread, thread.message.messages, show_icons: true,
                           hide_repeating_subjects: uconf('hide_subjects_unchanged') == 'yes')
    end
    html << '</article>'

    html.html_safe
  end
end
