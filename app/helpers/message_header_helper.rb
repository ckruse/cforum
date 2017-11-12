module MessageHeaderHelper
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

  def message_header_open_close_button(thread)
    if thread.attribs['open_state'] == 'closed'
      cf_button_to(open_cf_thread_path(thread),
                   params: std_args,
                   title: t('plugins.open_close.open_thread'),
                   class: 'icon-thread closed')
    else
      cf_button_to(close_cf_thread_path(thread),
                   params: std_args,
                   title: t('plugins.open_close.close_thread'),
                   class: 'icon-thread open')
    end
  end

  def message_header_hide_unhide_button(thread)
    if invisible?(current_user, thread).blank?
      cf_button_to(hide_cf_thread_path(thread),
                   params: std_args,
                   class: 'icon-thread mark-invisible',
                   title: t('plugins.invisible_threads.mark_thread_invisible'))
    else
      cf_button_to(unhide_cf_thread_path(thread),
                   params: std_args,
                   class: 'icon-thread mark-visible',
                   title: t('plugins.invisible_threads.mark_thread_visible'))
    end
  end

  def message_header_mark_thread_read_button(thread)
    cf_button_to(mark_cf_thread_read_path(thread),
                 params: std_args,
                 class: 'icon-thread mark-thread-read',
                 title: t('plugins.mark_read.mark_thread_read'))
  end

  def message_header_move_thread_button(thread)
    cf_link_to('', move_cf_thread_path(thread),
               class: 'icon-thread move',
               title: t('threads.move_thread'))
  end

  def message_header_sticky_thread_button(thread)
    cf_button_to(sticky_cf_thread_path(thread),
                 params: std_args,
                 class: 'icon-thread sticky',
                 title: (thread.sticky ? t('threads.mark_unsticky') : t('threads.mark_sticky')))
  end

  def message_header_no_archive_thread_button(thread)
    if thread.flags['no-archive'] == 'yes'
      cf_button_to(archive_cf_thread_path(thread),
                   params: std_args,
                   class: 'icon-thread archive',
                   title: t('plugins.no_answer_no_archive.arc'))
    else
      cf_button_to(no_archive_cf_thread_path(thread),
                   params: std_args,
                   class: 'icon-thread no-archive',
                   title: t('plugins.no_answer_no_archive.no_arc'))
    end
  end

  def message_header_delete_message_button(thread, message)
    if message.deleted?
      cf_button_to(restore_message_path(thread, message),
                   params: std_args,
                   class: 'icon-message restore',
                   title: t('messages.restore_message'))
    else
      cf_button_to(message_path(thread, message),
                   method: :delete,
                   params: std_args,
                   class: 'icon-message delete',
                   title: t('messages.delete_message'))
    end
  end

  def message_header_no_answer_message_button(thread, message)
    if !message.open?
      cf_button_to(allow_answer_message_path(thread, message),
                   params: std_args,
                   class: 'icon-message answer',
                   title: t('plugins.no_answer_no_archive.answer'))
    else
      cf_button_to(forbid_answer_message_path(thread, message),
                   params: std_args,
                   class: 'icon-message no-answer',
                   title: t('plugins.no_answer_no_archive.no_answer'))
    end
  end

  def message_header_interesting_message_button(thread, message)
    if message.attribs[:is_interesting]
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
  end

  def message_header_subscribe_message_button(thread, message)
    if message.attribs[:is_subscribed]
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

  def message_header_forum_plate(forum)
    cf_link_to(forum.short_name, forum_path(forum), class: 'thread-forum-plate') << "\n"
  end

  def message_header_classes(thread, message, opts)
    classes = ['message']
    classes += message.attribs['classes']
    classes << 'first' if opts[:first]
    classes << 'deleted' if message.deleted?
    classes << 'active' if opts[:active_message] && (opts[:active_message].message_id == message.message_id)

    classes << thread.attribs['open_state'] == 'closed' ? 'closed' : 'open'

    if thread.accepted.present?
      classes << 'accepted-answer' if thread.accepted.include?(message)
      classes << 'has-accepted-answer' if thread.message.message_id == message.message_id
    end
    if message.close_vote.present?
      classes << (message.close_vote.finished ? 'close-vote-finished' : 'close-vote-active')
    end
    if message.open_vote.present?
      classes << (message.close_vote.finished ? 'open-vote-finished' : 'open-vote-active')
    end

    classes << 'h-entry' if opts[:tree]

    classes
  end

  def message_header_header_element(thread, message, opts)
    classes = message_header_classes(thread, message, opts)

    html = '<header'
    html << ' class="' << classes.join(' ') << '"' if classes.present?
    if opts[:id]
      html << ' id="'
      html << opts[:id_prefix] if opts[:id_prefix].present?
      html << 'm' << message.message_id.to_s << '"'
    end
    html << ">\n"

    html
  end

  def message_header_thread_icons(thread, opts)
    html = ''
    has_open = false

    if opts[:first] && current_user && opts[:show_icons] && !@view_all
      has_open = true

      html << '<span class="thread-icons">'
      html << message_header_open_close_button(thread)
      html << message_header_hide_unhide_button(thread)
      html << message_header_mark_thread_read_button(thread)
    end

    if current_user.try(:moderate?, current_forum) && opts[:show_icons] && @view_all
      if opts[:first]
        unless has_open
          html << '<span class="thread-icons">'
          has_open = true
        end

        html << ' ' << message_header_move_thread_button(thread)
        html << message_header_sticky_thread_button(thread)
        html << message_header_no_archive_thread_button(thread)
        html << '</span>'
      end
    end

    html << '</span>' if has_open

    html
  end

  def message_header_message_icons(thread, message, opts)
    has_open = false
    html = ''

    if current_user.try(:moderate?, current_forum) && opts[:show_icons] && @view_all
      html << '<span class="message-icons">'
      has_open = true

      html << message_header_delete_message_button(thread, message) unless opts[:prev_deleted]
      html << message_header_no_answer_message_button(thread, message)
    end

    if current_user && opts[:show_icons] && !@view_all
      unless has_open
        html << '<span class="message-icons">'
        has_open = true
      end

      if !@view_all && ((message.flags['no-answer'] == 'yes') || (message.flags['no-answer-admin'] == 'yes'))
        html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
      end

      html << message_header_interesting_message_button(thread, message)
      html << message_header_subscribe_message_button(thread, message) unless opts[:parent_subscribed]
    elsif !@view_all && !message.open?
      html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
    end

    html << '</span>' if has_open

    html
  end

  def message_header_votes(message, opts)
    return '' unless opts[:show_icons]
    ' <span class="votes" title="' +
      t('messages.votes_tree', count: message.no_votes, score: message.score_str) + '">' +
      message.score.to_s + '</span>'
  end

  def message_header_num_infos(thread, opts)
    return '' unless opts[:show_icons]

    html = '<span class="num-infos"><span class="num-msgs" title="' +
           t('messages.num_messages', count: thread.messages.length) + '">' +
           thread.messages.length.to_s + '</span>'

    if thread.attribs[:msgs].present?
      html << '<span class="num-unread" title="' <<
        t('plugins.mark_read.num_unread', count: thread.attribs[:msgs][:unread]) << '">' <<
        thread.attribs[:msgs][:unread].to_s << '</span>'
    end

    html << '</span>'

    html
  end

  def message_header_subject(thread, message, opts)
    return '' unless opts[:subject]

    html = ''

    if opts[:first]
      html << message_header_num_infos(thread, opts)
      html << ' <h2 class="p-name">' <<
        cf_link_to(message.subject, message_path(thread, message), class: 'u-uid u-url') <<
        '</h2>'

    elsif thread.thread_id && message.message_id
      if (opts[:hide_repeating_subjects] && message.subject_changed?) || !(opts[:hide_repeating_subjects])
        html << '  <h3 class="p-name">' <<
          cf_link_to(message.subject, message_path(thread, message), class: 'u-uid u-url') <<
          '</h3>'
      end
    else
      html << '  <h3 class="p-name">' << message.subject << '</h3>'
    end

    html
  end

  def message_header_user_homepage_link(message)
    return '' if message.homepage.blank?

    if message.owner.try(:badge?, 'seo_profi') && (message.owner.try(:conf, 'norelnofollow') == 'yes')
      ' ' + cf_link_to('', message.homepage, class: 'author-homepage u-url', rel: nil)
    else
      ' ' + cf_link_to('', message.homepage, class: 'author-homepage u-url')
    end
  end

  def message_header_email_link(message)
    return '' if message.email.blank?
    cf_link_to('', 'mailto:' + message.email, class: 'author-email u-email')
  end

  def message_header_author_link(thread, message, opts)
    if opts[:author_link_to_message]
      cf_link_to(message.author, message_path(thread, message), 'aria-hidden' => 'true', class: 'p-name')
    elsif message.user_id
      cf_link_to(message.author, user_path(message.user_id), class: 'p-name u-uid u-url')
    else
      content_tag(:span, message.author.to_s, class: 'p-name')
    end
  end

  def message_header_author(thread, message, opts)
    html = '<span class="author p-author h-card">'

    if message.user_id
      html << '<span class="registered-user'
      if (message.message_id != thread.message.try(:message_id)) && (message.user_id == thread.message.try(:user_id))
        html << ' original-poster'
      end

      html << '">' << cf_link_to("<span class=\"visually-hidden\">#{t('messages.link_to_profile_of')}" \
                                 ' </span>'.html_safe +
                                 image_tag(message.owner.avatar(:thumb),
                                           class: "avatar#{' u-photo' if message.owner.avatar.present?}",
                                           alt: t('messages.user_link', user: message.owner.username)),
                                 user_path(message.owner),
                                 title: t('messages.user_link', user: message.owner.username),
                                 class: 'user-link') << ' '
    elsif (message.message_id != thread.message.try(:message_id)) &&
          message.uuid.present? && (message.uuid == thread.message.try(:uuid))
      html << '<span class="icon-message original-poster" title="' << t('messages.original_poster') << '"> </span>'
    end

    html << message_header_author_link(thread, message, opts)

    html << '</span>' if message.user_id

    if !(opts[:tree]) && !thread.archived? && (message.email.present? || message.homepage.present?)
      content_tag(:span, class: 'author-infos') do
        ' ' + message_header_email_link(message) + message_header_user_homepage_link(message)
      end
    end

    if current_user.try(:moderate?, current_forum) && @view_all
      html << ' ' << content_tag(:span, message.ip, class: 'admin-infos ip') if message.ip.present?
      html << ' ' << content_tag(:span, message.uuid, class: 'admin-infos uuid') if message.uuid.present?
    end

    html << '</span> '

    html
  end

  def message_header_time(thread, message, opts)
    dformat = if opts[:tree]
                date_format('date_format_index' + day_changed_key(message))
              else
                date_format('date_format_post')
              end

    text = time_tag(message.created_at, l(message.created_at, format: dformat), class: 'dt-published')
    cf_link_to_if(thread.thread_id && message.message_id, text, message_path(thread, message))
  end

  def message_header_versions(thread, message, opts)
    return '' if !opts[:show_editor] || message.edit_author.blank? || message.versions.blank?

    content_tag(:span, class: 'versions') do
      (' (' + cf_link_to(t('messages.versions'), versions_message_path(thread, message),
                         rel: 'nofollow',
                         class: 'version-link') + ')').html_safe
    end
  end

  def message_header_tags(thread, message, opts)
    return '' if message.tags.blank? || !opts[:tags] || (opts[:hide_repeating_tags] && !message.tags_changed?)

    html = ' <ul class="cf-tags-list">'

    message.tags.each do |tag|
      html << '<li class="cf-tag p-category">' << cf_link_to(tag.tag_name, tag_path(thread.forum.slug, tag)) << '</li>'
    end

    html << '</ul>'
    html
  end

  def message_header_vote_details(message, opts)
    return '' unless opts[:show_votes]

    ' <span class="votes" title="' <<
      t('messages.votes_tree', count: message.no_votes, score: message.score_str) <<
      '">' <<
      t('messages.votes', count: message.no_votes, score: message.score_str) <<
      '</span>'
  end

  def message_header_details(thread, message, opts)
    html = ' <div class="details">'
    html << message_header_author(thread, message, opts)
    html << message_header_time(thread, message, opts)
    html << message_header_versions(thread, message, opts)
    html << message_header_tags(thread, message, opts)
    html << message_header_vote_details(message, opts)
    html << '</div>'

    html
  end
end

# eof
