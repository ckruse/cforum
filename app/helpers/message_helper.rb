# -*- coding: utf-8 -*-

module MessageHelper
  def std_args(args = {})
    local_args = {p: params[:p],
                  page: params[:page],
                  r: controller_path,
                  f: current_forum.try(:slug) || 'all'}
    local_args.delete(:p) if local_args[:p].blank?
    local_args.delete(:page) if local_args[:page].blank?
    local_args.merge(args)
  end

  def message_header(thread, message, opts = {})
    opts = {first: false, prev_deleted: false,
      show_icons: false, do_parent: false,
      tree: true, id: true, hide_repeating_subjects: false,
      show_editor: false, id_prefix: nil, active_message: @message,
      subject: true, tags: true, author_link_to_message: true}.merge(opts)

    classes = ['message']
    classes += message.attribs['classes']
    classes << 'first' if opts[:first]
    classes << 'deleted' if message.deleted?
    classes << 'active' if opts[:active_message] and opts[:active_message].message_id == message.message_id

    classes << thread.attribs['open_state'] == 'closed' ? 'closed' : 'open'

    if not thread.accepted.blank?
      classes << "accepted-answer" if thread.accepted.include?(message)
      classes << "has-accepted-answer" if thread.message.message_id == message.message_id
    end
    unless message.close_vote.blank?
      classes << (message.close_vote.finished ? "close-vote-finished" :
                  "close-vote-active")
    end
    unless message.open_vote.blank?
      classes << (message.close_vote.finished ? "open-vote-finished" :
                  "open-vote-active")
    end

    html = "<header"
    html << ' class="' << classes.join(" ") << '"' unless classes.blank?
    if opts[:id]
      html << ' id="'
      html << opts[:id_prefix] unless opts[:id_prefix].blank?
      html << 'm' << message.message_id.to_s << '"'
    end
    html << ">\n"

    opened = []

    if opts[:first] and current_user and opts[:show_icons] and not @view_all
      html << "<span class=\"thread-icons\">"
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

    if not current_user.blank? and (current_user.admin? or current_user.moderate?(current_forum)) and opts[:show_icons] and @view_all
      if opts[:first]
        unless opened.include?('span')
          html << "<span class=\"thread-icons\">"
          opened << 'span'
        end

        html << " " << cf_link_to('', move_cf_thread_path(thread), class: 'icon-thread move', title: t('threads.move_thread'))

        html << cf_button_to(sticky_cf_thread_path(thread), params: std_args, class: 'icon-thread sticky', title: (thread.sticky ? t('threads.mark_unsticky') : t('threads.mark_sticky')))

        if thread.flags['no-archive'] == 'yes'
          html << cf_button_to(no_archive_cf_thread_path(thread), params: std_args, class: 'icon-thread archive', title: t('plugins.no_answer_no_archive.arc'))
        else
          html << cf_button_to(no_archive_cf_thread_path(thread), params: std_args, class: 'icon-thread no-archive', title: t('plugins.no_answer_no_archive.no_arc'))
        end

        html << "</span>"
        opened.pop
      end

      html << "<span class=\"message-icons\">"
      opened << 'span'

      if not opts[:prev_deleted]
        if message.deleted?
          html << cf_button_to(restore_cf_message_path(thread, message), params: std_args, class: 'icon-message restore', title: t('messages.restore_message'))
        else
          html << cf_button_to(cf_message_path(thread, message), method: :delete, params: std_args, class: 'icon-message delete', title: t('messages.delete_message'))
        end
      end

      if not message.open?
        html << cf_button_to(no_answer_cf_message_path(thread, message), params: std_args, class: 'icon-message answer', title: t('plugins.no_answer_no_archive.answer'))
      else
        html << cf_button_to(no_answer_cf_message_path(thread, message), params: std_args, class: 'icon-message no-answer', title: t('plugins.no_answer_no_archive.no_answer'))
      end
    end

    for el in opened
      html << '</' << el << '>'
    end

    if current_user and opts[:show_icons] and not @view_all
      html << "<span class=\"message-icons\">"

      if not @view_all and (message.flags['no-answer'] == 'yes' or message.flags['no-answer-admin'] == 'yes')
        html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
      end

      if message.attribs[:is_interesting]
        html << cf_button_to(boring_cf_message_path(thread, message),
                             params: std_args,
                             class: "icon-message mark-boring",
                             title: t('plugins.interesting_messages.mark_message_boring'))
      else
        html << cf_button_to(interesting_cf_message_path(thread, message),
                             params: std_args,
                             class: "icon-message mark-interesting",
                             title: t('plugins.interesting_messages.mark_message_interesting'))
      end

      html << "</span>"
    else
      if not @view_all and (message.flags['no-answer'] == 'yes' or message.flags['no-answer-admin'] == 'yes')
        html << '<span class="icon-message no-answer user" title="' + t('messages.is_no_answer') + '"> </span>'
      end
    end


    if opts[:first] and current_forum.blank?
      html << "  " << cf_link_to(thread.forum.short_name, cf_forum_path(thread.forum), class: 'thread-forum-plate') << "\n"
    end

    if opts[:show_icons]
      html << ' <span class="votes" title="' << t('messages.votes_tree', count: message.no_votes, score: message.score_str) << '">' << message.score.to_s << '</span>'
    end

    if opts[:subject]
      if opts[:first]
        if opts[:show_icons]
          html << "<span class=\"num-infos\"><span class=\"num-msgs\" title=\"" << t("messages.num_messages",
                                                                                     count: thread.messages.length) << "\">" << thread.messages.length.to_s << "</span>"
          unless thread.attribs[:msgs].blank?
            html << "<span class=\"num-unread\" title=\"" << t("plugins.mark_read.num_unread", count: thread.attribs[:msgs][:unread]) << "\">" << thread.attribs[:msgs][:unread].to_s << "</span>"
          end
          html << "</span>"
        end

        html << " <h2>" << cf_link_to(message.subject, cf_message_path(thread, message)) << "</h2>"
      else
        if thread.thread_id and message.message_id
          if (opts[:hide_repeating_subjects] and message.subject_changed?) or not opts[:hide_repeating_subjects]
            html << "  <h3>" << cf_link_to(message.subject, cf_message_path(thread, message)) << "</h3>"
          end
        else
          html << "  <h3>" << message.subject << "</h3>"
        end
      end
    end

    html << %q{
  <div class="details">
      }

    html << " " << %q{
      <span class="author">}

    if message.user_id
      html << "<span class=\"registered-user"
      if not message.message_id == thread.message.message_id and message.user_id == thread.message.user_id
        html << " original-poster"
      end
      html << "\">" << cf_link_to(image_tag(message.owner.avatar(:thumb), class: 'avatar'), user_path(message.owner), title: t('messages.user_link', user: message.owner.username), class: 'user-link') << " "
    else
      if not message.message_id == thread.message.message_id and not message.uuid.blank? and message.uuid == thread.message.uuid
        html << '<span class="icon-message original-poster" title="' << t('messages.original_poster') << '"> </span>'
      end
    end

    if opts[:author_link_to_message]
      html << cf_link_to(message.author, cf_message_path(thread, message))
    elsif message.user_id
      html << cf_link_to(message.author, user_path(message.user_id))
    else
      html << message.author
    end

    html << '</span>' if message.user_id

    if not opts[:tree] and not thread.archived? and (not message.email.blank? or not message.homepage.blank?)
      html << ' <span class="author-infos">'
      html << ' ' << cf_link_to('', 'mailto:' + message.email, class: 'author-email') if not message.email.blank?

      if not message.homepage.blank?
        if not message.user_id.blank? and message.owner.has_badge?('seo_profi') and message.owner.conf('norelnofollow') == 'yes'
          html << ' ' << cf_link_to('', message.homepage, class: 'author-homepage', rel: nil)
        else
          html << ' ' << cf_link_to('', message.homepage, class: 'author-homepage')
        end
      end
      html << "</span>"
    end

    if current_user and (current_user.admin? or (current_forum and current_user.moderate?(current_forum))) and @view_all
      if not message.ip.blank?
        html << " <span class=\"admin-infos ip\">" << message.ip << "</span>"
      end
      if not message.uuid.blank?
        html << " <span class=\"admin-infos uuid\">" << message.uuid << "</span>"
      end
    end

    html << "</span> "

    text = "<time datetime=\"" << message.created_at.strftime("%FT%T%:z") << '">' <<
           encode_entities(l(message.created_at, format: opts[:tree] ?
                                                   date_format("date_format_index") :
                                                   date_format("date_format_post"))) <<
           "</time>"

    if thread.thread_id and message.message_id
      html << cf_link_to(cf_message_path(thread, message)) do
        text.html_safe
      end
    else
      html << text.html_safe
    end

    if opts[:show_editor] && !message.edit_author.blank? && !message.versions.blank?
      html << " <span class=\"versions\">(" << cf_link_to(t('messages.versions'),
                                                          versions_cf_message_path(thread, message),
                                                          rel: 'no-follow',
                                                          class: 'version-link')

      html << ")</span>"
    end

    if not message.tags.blank? and opts[:tags]
      html << %q{

    <ul class="cf-tags-list">}

      for t in message.tags
        html << "<li class=\"cf-tag\">" << cf_link_to(t.tag_name, tag_path(thread.forum.slug, t)) << "</li>"
      end

      html << "</ul>"
    end

    if opts[:show_votes]
      html << ' <span class="votes" title="' <<
        t('messages.votes_tree', count: message.no_votes, score: message.score_str) <<
        '">' <<
        t('messages.votes', count: message.no_votes, score: message.score_str) <<
        '</span>'
    end


    html << %q{
  </div>
</header>}

    html.html_safe
  end

  def message_tree(thread, messages, opts = {})
    opts = {prev_deleted: false, show_icons: false, id: true,
            hide_repeating_subjects: false,
            active_message: @message, subject: true,
            tags: true, id_prefix: nil}.merge(opts)

    html = "<ol>\n"
    for message in messages
      classes = []

      html << "<li"
      html << " class=\"" << classes.join(" ") << "\"" unless classes.blank?
      html << ">"
      html << message_header(thread, message, first: false,
                             prev_deleted: opts[:prev_deleted],
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects],
                             active_message: opts[:active_message],
                             id_prefix: opts[:id_prefix])
      html << message_tree(thread, message.messages, first: false,
                           prev_deleted: message.deleted?,
                           show_icons: opts[:show_icons],
                           id: opts[:id],
                           hide_repeating_subjects: opts[:hide_repeating_subjects],
                           active_message: opts[:active_message],
                           id_prefix: opts[:id_prefix]) unless message.messages.blank?
      html << "</li>"
    end

    html << "\n</ol>"

    html.html_safe
  end

  def set_message_attibutes(message, thread, user = current_user, parent = nil)
    message.forum_id   = thread.forum_id
    message.user_id    = user.try(:user_id)
    message.thread_id  = thread.thread_id

    message.content    = CfMessage.to_internal(message.content)

    message.created_at = Time.zone.now
    message.updated_at = message.created_at
    message.ip         = Digest::SHA1.hexdigest(request.remote_ip)

    message.parent_id  = parent.try(:message_id)
  end

  def set_message_author(message, author = current_user.try(:username))
    if not author.blank?
      @message.author = author
    elsif not @message.author.blank?
      unless CfUser.where('LOWER(username) = LOWER(?)', @message.author.strip).first.blank?
        flash.now[:error] = I18n.t('errors.name_taken')
        return false
      end
    end

    return true
  end

  def set_user_cookies(message)
    unless current_user
      cookies[:cforum_user] = {value: request.uuid, expires: 1.year.from_now} if cookies[:cforum_user].blank?
      message.uuid = cookies[:cforum_user]

      cookies[:cforum_author]   = {value: @message.author, expires: 1.year.from_now}
      cookies[:cforum_email]    = {value: @message.email, expires: 1.year.from_now}
      cookies[:cforum_homepage] = {value: @message.homepage, expires: 1.year.from_now}
    end
  end
end

# eof
