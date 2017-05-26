# -*- coding: utf-8 -*-

module MessageHelper
  def std_args(args = {})
    local_args = { p: params[:p],
                   page: params[:page],
                   r: controller_path,
                   f: current_forum.try(:slug) || 'all' }
    local_args.delete(:p) if local_args[:p].blank?
    local_args.delete(:page) if local_args[:page].blank?
    local_args.merge(args)
  end

  def day_changed_key(message)
    return '' if uconf('hide_repeating_date') == 'no'

    if message.prev.blank? || message.day_changed?(message.prev)
      ''
    else
      '_sameday'
    end
  end

  def message_header(thread, message, opts = {})
    opts = { first: false, prev_deleted: false,
             show_icons: false, do_parent: false,
             tree: true, id: true, hide_repeating_subjects: false,
             show_editor: false, id_prefix: nil, active_message: @message,
             subject: true, tags: true, author_link_to_message: true,
             parent_subscribed: false }.merge(opts)

    classes = ['message']
    classes += message.attribs['classes']
    classes << 'first' if opts[:first]
    classes << 'deleted' if message.deleted?
    classes << 'active' if opts[:active_message] && (opts[:active_message].message_id == message.message_id)

    classes << thread.attribs['open_state'] == 'closed' ? 'closed' : 'open'

    unless thread.accepted.blank?
      classes << 'accepted-answer' if thread.accepted.include?(message)
      classes << 'has-accepted-answer' if thread.message.message_id == message.message_id
    end
    unless message.close_vote.blank?
      classes << (message.close_vote.finished ? 'close-vote-finished' :
                  'close-vote-active')
    end
    unless message.open_vote.blank?
      classes << (message.close_vote.finished ? 'open-vote-finished' :
                  'open-vote-active')
    end

    classes << 'h-entry' if opts[:tree]

    html = '<header'
    html << ' class="' << classes.join(' ') << '"' unless classes.blank?
    if opts[:id]
      html << ' id="'
      html << opts[:id_prefix] unless opts[:id_prefix].blank?
      html << 'm' << message.message_id.to_s << '"'
    end
    html << ">\n"

    opened = []

    if opts[:first] && current_user && opts[:show_icons] && !@view_all
      html << '<span class="thread-icons">'
      opened << 'span'

      if thread.attribs['open_state'] == 'closed'
        html << cf_button_to(open_cf_thread_path(thread), params: std_args, title: t('plugins.open_close.open_thread'), class: 'icon-thread closed')
      else
        html << cf_button_to(close_cf_thread_path(thread), params: std_args, title: t('plugins.open_close.close_thread'), class: 'icon-thread open')
      end

      if is_invisible(current_user, thread).blank?
        html << cf_button_to(hide_cf_thread_path(thread), params: std_args, class: 'icon-thread mark-invisible', title: t('plugins.invisible_threads.mark_thread_invisible'))
      else
        html << cf_button_to(unhide_cf_thread_path(thread), params: std_args, class: 'icon-thread mark-visible', title: t('plugins.invisible_threads.mark_thread_visible'))
      end

      html << cf_button_to(mark_cf_thread_read_path(thread), params: std_args, class: 'icon-thread mark-thread-read', title: t('plugins.mark_read.mark_thread_read'))
    end

    if !current_user.blank? && (current_user.admin? || current_user.moderate?(current_forum)) && opts[:show_icons] && @view_all
      if opts[:first]
        unless opened.include?('span')
          html << '<span class="thread-icons">'
          opened << 'span'
        end

        html << ' ' << cf_link_to('', move_cf_thread_path(thread), class: 'icon-thread move', title: t('threads.move_thread'))

        html << cf_button_to(sticky_cf_thread_path(thread), params: std_args, class: 'icon-thread sticky', title: (thread.sticky ? t('threads.mark_unsticky') : t('threads.mark_sticky')))

        if thread.flags['no-archive'] == 'yes'
          html << cf_button_to(archive_cf_thread_path(thread), params: std_args, class: 'icon-thread archive', title: t('plugins.no_answer_no_archive.arc'))
        else
          html << cf_button_to(no_archive_cf_thread_path(thread), params: std_args, class: 'icon-thread no-archive', title: t('plugins.no_answer_no_archive.no_arc'))
        end

        html << '</span>'
        opened.pop
      end

      html << '<span class="message-icons">'
      opened << 'span'

      unless opts[:prev_deleted]
        if message.deleted?
          html << cf_button_to(restore_message_path(thread, message), params: std_args, class: 'icon-message restore', title: t('messages.restore_message'))
        else
          html << cf_button_to(message_path(thread, message), method: :delete, params: std_args, class: 'icon-message delete', title: t('messages.delete_message'))
        end
      end

      if !message.open?
        html << cf_button_to(allow_answer_message_path(thread, message), params: std_args, class: 'icon-message answer', title: t('plugins.no_answer_no_archive.answer'))
      else
        html << cf_button_to(forbid_answer_message_path(thread, message), params: std_args, class: 'icon-message no-answer', title: t('plugins.no_answer_no_archive.no_answer'))
      end
    end

    for el in opened
      html << '</' << el << '>'
    end

    if current_user && opts[:show_icons] && !@view_all
      html << '<span class="message-icons">'

      if !@view_all && ((message.flags['no-answer'] == 'yes') || (message.flags['no-answer-admin'] == 'yes'))
        html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
      end

      html << if message.attribs[:is_interesting]
                cf_button_to(boring_message_path(thread, message),
                             params: std_args,
                             class: 'icon-message mark-boring',
                             title: t('plugins.interesting_messages.mark_message_boring'))
              else
                cf_button_to(interesting_message_path(thread, message),
                             params: std_args,
                             class: 'icon-message mark-interesting',
                             title: t('plugins.interesting_messages.mark_message_interesting'))
              end

      unless opts[:parent_subscribed]
        html << if message.attribs[:is_subscribed]
                  cf_button_to(unsubscribe_message_path(thread, message),
                               params: std_args,
                               class: 'icon-message unsubscribe',
                               title: t('plugins.subscriptions.unsubscribe_message'))
                else
                  cf_button_to(subscribe_message_path(thread, message),
                               params: std_args,
                               class: 'icon-message subscribe',
                               title: t('plugins.subscriptions.subscribe_message'))
                end
      end

      html << '</span>'
    else
      if !@view_all && ((message.flags['no-answer'] == 'yes') || (message.flags['no-answer-admin'] == 'yes'))
        html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
      end
    end

    if opts[:first] && current_forum.blank?
      html << '  ' << cf_link_to(thread.forum.short_name, forum_path(thread.forum), class: 'thread-forum-plate') << "\n"
    end

    if opts[:show_icons]
      html << ' <span class="votes" title="' << t('messages.votes_tree', count: message.no_votes, score: message.score_str) << '">' << message.score.to_s << '</span>'
    end

    if opts[:subject]
      if opts[:first]
        if opts[:show_icons]
          html << '<span class="num-infos"><span class="num-msgs" title="' << t('messages.num_messages',
                                                                                count: thread.messages.length) << '">' << thread.messages.length.to_s << '</span>'
          unless thread.attribs[:msgs].blank?
            html << '<span class="num-unread" title="' << t('plugins.mark_read.num_unread', count: thread.attribs[:msgs][:unread]) << '">' << thread.attribs[:msgs][:unread].to_s << '</span>'
          end
          html << '</span>'
        end

        html << ' <h2 class="p-name">' << cf_link_to(message.subject, message_path(thread, message), class: 'u-uid u-url') << '</h2>'
      else
        if thread.thread_id && message.message_id
          if (opts[:hide_repeating_subjects] && message.subject_changed?) || !(opts[:hide_repeating_subjects])
            html << '  <h3 class="p-name">' << cf_link_to(message.subject, message_path(thread, message), class: 'u-uid u-url') << '</h3>'
          end
        else
          html << '  <h3 class="p-name">' << message.subject << '</h3>'
        end
      end
    end

    html << '
  <div class="details">
      '

    html << ' ' << '
      <span class="author p-author h-card">'

    if message.user_id
      html << '<span class="registered-user'
      if (message.message_id != thread.message.try(:message_id)) && (message.user_id == thread.message.try(:user_id))
        html << ' original-poster'
      end
      html << '">' << cf_link_to("<span class=\"visually-hidden\">#{t('messages.link_to_profile_of')} </span>".html_safe +
                                  image_tag(message.owner.avatar(:thumb), class: "avatar#{' u-photo' if message.owner.avatar.present?}",
                                                                          alt: t('messages.user_link', user: message.owner.username)),
                                 user_path(message.owner),
                                 title: t('messages.user_link',
                                          user: message.owner.username),
                                 class: 'user-link') << ' '
    else
      if (message.message_id != thread.message.try(:message_id)) && !message.uuid.blank? && (message.uuid == thread.message.try(:uuid))
        html << '<span class="icon-message original-poster" title="' << t('messages.original_poster') << '"> </span>'
      end
    end

    html << if opts[:author_link_to_message]
              cf_link_to(message.author, message_path(thread, message), 'aria-hidden' => 'true', class: 'p-name')
            elsif message.user_id
              cf_link_to(message.author, user_path(message.user_id), class: 'p-name u-uid u-url')
            else
              content_tag(:span, message.author.to_s, class: 'p-name')
            end

    html << '</span>' if message.user_id

    if !(opts[:tree]) && !thread.archived? && (!message.email.blank? || !message.homepage.blank?)
      html << ' <span class="author-infos">'
      html << ' ' << cf_link_to('', 'mailto:' + message.email, class: 'author-email u-email') unless message.email.blank?

      unless message.homepage.blank?
        if !message.user_id.blank? && message.owner.has_badge?('seo_profi') && (message.owner.conf('norelnofollow') == 'yes')
          html << ' ' << cf_link_to('', message.homepage, class: 'author-homepage u-url', rel: nil)
        else
          html << ' ' << cf_link_to('', message.homepage, class: 'author-homepage u-url')
        end
      end
      html << '</span>'
    end

    if current_user && (current_user.admin? || (current_forum && current_user.moderate?(current_forum))) && @view_all
      unless message.ip.blank?
        html << ' <span class="admin-infos ip">' << message.ip << '</span>'
      end
      unless message.uuid.blank?
        html << ' <span class="admin-infos uuid">' << message.uuid << '</span>'
      end
    end

    html << '</span> '

    dformat = if opts[:tree]
                date_format('date_format_index' + day_changed_key(message))
              else
                date_format('date_format_post')
              end

    text = time_tag(message.created_at, l(message.created_at, format: dformat), class: 'dt-published')

    html << cf_link_to_if(thread.thread_id && message.message_id, text, message_path(thread, message)) do
      text
    end

    if opts[:show_editor] && !message.edit_author.blank? && !message.versions.blank?
      html << ' <span class="versions">(' << cf_link_to(t('messages.versions'),
                                                        versions_message_path(thread, message),
                                                        rel: 'nofollow',
                                                        class: 'version-link')

      html << ')</span>'
    end

    if !message.tags.blank? && opts[:tags] && (!opts[:hide_repeating_tags] || message.tags_changed?)
      html << '

    <ul class="cf-tags-list">'

      message.tags.each do |t|
        html << '<li class="cf-tag p-category">' << cf_link_to(t.tag_name, tag_path(thread.forum.slug, t)) << '</li>'
      end

      html << '</ul>'
    end

    if opts[:show_votes]
      html << ' <span class="votes" title="' <<
        t('messages.votes_tree', count: message.no_votes, score: message.score_str) <<
        '">' <<
        t('messages.votes', count: message.no_votes, score: message.score_str) <<
        '</span>'
    end

    html << '
  </div>
</header>'

    html.html_safe
  end

  def message_tree(thread, messages, opts = {})
    opts = { prev_deleted: false, show_icons: false, id: true,
             hide_repeating_subjects: false, hide_repeating_tags: false,
             active_message: @message, subject: true,
             tags: true, id_prefix: nil,
             parent_subscribed: false }.merge(opts)

    html = "<ol>\n"
    for message in messages
      classes = []

      html << '<li'
      html << ' class="' << classes.join(' ') << '"' unless classes.blank?
      html << '>'
      html << message_header(thread, message,
                             first: false,
                             prev_deleted: opts[:prev_deleted],
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects],
                             hide_repeating_tags: opts[:hide_repeating_tags],
                             active_message: opts[:active_message],
                             id_prefix: opts[:id_prefix],
                             parent_subscribed: opts[:parent_subscribed])

      unless message.messages.blank?
        html << message_tree(thread, message.messages,
                             first: false,
                             prev_deleted: message.deleted?,
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects],
                             hide_repeating_tags: opts[:hide_repeating_tags],
                             active_message: opts[:active_message],
                             id_prefix: opts[:id_prefix],
                             parent_subscribed: opts[:parent_subscribed] || message.attribs[:is_subscribed])
      end

      html << '</li>'
    end

    html << "\n</ol>"

    html.html_safe
  end

  def set_message_attibutes(message, thread, user = current_user, parent = nil)
    message.forum_id   = thread.forum_id
    message.user_id    = user.try(:user_id)
    message.thread_id  = thread.thread_id

    message.content    = Message.to_internal(message.content)

    message.created_at = Time.zone.now
    message.updated_at = message.created_at
    message.ip         = Digest::SHA1.hexdigest(request.remote_ip)

    message.parent_id  = parent.try(:message_id)

    flattr_id = uconf('flattr')
    message.flags['flattr_id'] = flattr_id unless flattr_id.blank?
  end

  def set_message_author(_message, author = current_user.try(:username))
    if !author.blank?
      @message.author = author
    elsif !@message.author.blank?
      unless User.where('LOWER(username) = LOWER(?)', @message.author.strip).first.blank?
        flash.now[:error] = I18n.t('errors.name_taken')
        return false
      end
    end

    true
  end

  def set_user_cookies(message)
    return if current_user

    cookies[:cforum_user] = { value: request.uuid, expires: 1.year.from_now } if cookies[:cforum_user].blank?
    message.uuid = cookies[:cforum_user]

    cookies[:cforum_author]   = { value: @message.author, expires: 1.year.from_now }
    cookies[:cforum_email]    = { value: @message.email, expires: 1.year.from_now }
    cookies[:cforum_homepage] = { value: @message.homepage, expires: 1.year.from_now }
  end

  def std_conditions(conditions, tid = false)
    if conditions.is_a?(String) || conditions.is_a?(Integer)
      conditions = if tid
                     { thread_id: conditions }
                   else
                     { slug: conditions }
                   end
    end

    conditions[:messages] = { deleted: false } unless @view_all

    conditions
  end

  def get_thread(thread_id = nil)
    tid = false
    id  = nil

    if !thread_id.nil?
      id = thread_id
      tid = true
    elsif params[:year] && params[:mon] && params[:day] && params[:tid]
      id = CfThread.make_id(params)
    else
      id = params[:id]
      tid = true
    end

    thread = CfThread
               .preload(:forum,
                        messages: [:editor, :tags, :thread, :versions, :cite, :open_moderation_queue_entry,
                                   { votes: :voters,
                                     owner: %i[settings badges],
                                     message_references: { src_message: [{ thread: :forum },
                                                                         :owner, :tags, :votes] } }])
               .includes(messages: :owner)
               .where(std_conditions(id, tid))
               .references(messages: :owner)
               .first

    raise ActiveRecord::RecordNotFound if thread.blank?

    # sort messages
    sort_thread(thread)

    [thread, id]
  end

  def get_thread_w_post(tid = nil, mid = nil)
    thread, id = get_thread(tid)

    mid = params[:mid] if mid.nil?
    message = nil

    unless mid.blank?
      mid = mid.to_i if mid.is_a?(String)
      message = thread.find_message(mid)
      raise ActiveRecord::RecordNotFound if message.nil?
    end

    [thread, message, id]
  end

  def positive_score_class(score)
    case score
    when 0..3
      'positive-score'
    when 4
      'positiver-score'
    else
      'best-score'
    end
  end

  def negative_score_class(score)
    case score
    when 0..3
      'negative-score'
    when 4
      'negativer-score'
    else
      'negative-bad-score'
    end
  end

  def score_class(score)
    return '' if score.zero?

    if score >= 0
      positive_score_class(score)
    else
      negative_score_class(score.abs)
    end
  end

  def message_classes(msg, thread, active, rm = :thread)
    classes = []
    classes << 'active' if active
    classes << 'interesting' if msg.attribs[:is_interesting]
    classes << 'accepted' if thread.accepted.include?(msg)

    if uconf('fold_read_nested') == 'yes' && rm == :nested && !active &&
       !thread.archived && msg.attribs['classes'].include?('visited')
      classes << 'folded'
    end

    classes << score_class(msg.score)

    classes.join(' ')
  end

  def flag_reason(msg)
    flag_reason_entry(msg.open_moderation_queue_entry)
  end

  def flag_reason_entry(entry)
    case entry.reason
    when 'custom'
      entry.custom_reason
    when 'duplicate'
      cf_link_to I18n.t('plugins.flag_plugin.duplicate_message'), entry.duplicate_url
    else
      I18n.t('messages.close_vote.' + entry.reason)
    end
  end
end

# eof
