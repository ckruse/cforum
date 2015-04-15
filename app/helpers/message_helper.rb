# -*- coding: utf-8 -*-

module MessageHelper
  def std_args(args = {})
    local_args = {p: params[:p], r: controller_path, f: current_forum.try(:slug) || 'all'}
    local_args.delete(:p) if local_args[:p].blank?
    local_args.merge(args)
  end

  def message_header(thread, message, opts = {})
    opts = {first: false, prev_deleted: false,
      show_icons: false, do_parent: false,
      tree: true, id: true, hide_repeating_subjects: false,
      id_prefix: nil}.merge(opts)

    classes = ['message']
    classes += message.attribs['classes']
    classes << 'first' if opts[:first]
    classes << 'deleted' if message.deleted?
    classes << 'active' if @message and @message.message_id == message.message_id

    if thread.accepted
      classes << "accepted-answer" if thread.accepted.message_id == message.message_id
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
    html << ' class="' + classes.join(" ") + '"' unless classes.blank?
    if opts[:id]
      html << ' id="'
      html << opts[:id_prefix] unless opts[:id_prefix].blank?
      html << 'm' + message.message_id.to_s + '"'
    end
    html << ">\n"

    opened = []

    if opts[:first] and current_user and opts[:show_icons] and not @view_all
      html << "<span class=\"thread-icons\">"
      opened << 'span'

      if thread.attribs['open_state'] == 'closed'
        html << button_to(open_cf_thread_path(thread), params: std_args, title: t('plugins.open_close.open_thread'), class: 'icon-thread closed') do
          ''
        end
      else
        html << button_to(close_cf_thread_path(thread), params: std_args, title: t('plugins.open_close.close_thread'), class: 'icon-thread open') do
          ''
        end
      end

      if get_plugin_api(:is_invisible).call(thread, current_user).blank?
        html << button_to(hide_cf_thread_path(thread), params: std_args, class: 'icon-thread mark-invisible', title: t('plugins.invisible_threads.mark_thread_invisible')) do
          ''
        end
      else
        html << button_to(unhide_cf_thread_path(thread), params: std_args, class: 'icon-thread mark-visible', title: t('plugins.invisible_threads.mark_thread_visible')) do
          ''
        end
      end


      if get_plugin_api(:is_interesting).call(thread, current_user).blank?
        html << button_to(interesting_cf_thread_path(thread), params: std_args, class: "icon-thread mark-interesting", title: t('plugins.interesting_threads.mark_thread_interesting')) do
          ''
        end
      else
        html << button_to(boring_cf_thread_path(thread), params: std_args, class: "icon-thread mark-boring", title: t('plugins.interesting_threads.mark_thread_boring')) do
          ''
        end
      end

      html << button_to(mark_cf_thread_read_path(thread), params: std_args, class: 'icon-thread mark-thread-read', title: t('plugins.mark_read.mark_thread_read')) do
        ''
      end
    end

    if not current_user.blank? and (current_user.admin? or current_user.moderate?(current_forum)) and opts[:show_icons] and @view_all
      if opts[:first]
        unless opened.include?('span')
          html << "<span class=\"thread-icons\">"
          opened << 'span'
        end

        html << " " + link_to('', move_cf_thread_path(thread), class: 'icon-thread move', title: t('threads.move_thread'))

        html << button_to(sticky_cf_thread_path(thread), params: std_args, class: 'icon-thread sticky', title: (thread.sticky ? t('threads.mark_unsticky') : t('threads.mark_sticky'))) do
          ''
        end

        if thread.flags['no-archive'] == 'yes'
          html << button_to(no_archive_cf_thread_path(thread), params: std_args, class: 'icon-thread archive', title: t('plugins.no_answer_no_archive.arc')) do
            ''
          end
        else
          html << button_to(no_archive_cf_thread_path(thread), params: std_args, class: 'icon-thread no-archive', title: t('plugins.no_answer_no_archive.no_arc')) do
            ''
          end
        end

        html << "</span>"
        opened.pop
      end

      html << "<span class=\"message-icons\">"
      opened << 'span'

      if not opts[:prev_deleted]
        if message.deleted?
          html << button_to(restore_cf_message_path(thread, message), params: std_args, class: 'icon-message restore', title: t('messages.restore_message')) do
            ''
          end
        else
          html << button_to(cf_message_path(thread, message), method: :delete, params: std_args, class: 'icon-message delete', title: t('messages.delete_message')) do
            ''
          end
        end
      end

      if not message.open?
        html << button_to(no_answer_cf_message_path(thread, message), params: std_args, class: 'icon-message answer', title: t('plugins.no_answer_no_archive.answer')) do
          ''
        end
      else
        html << button_to(no_answer_cf_message_path(thread, message), params: std_args, class: 'icon-message no-answer', title: t('plugins.no_answer_no_archive.no_answer')) do
          ''
        end
      end
    end

    opened.each do |el|
      html << '</' + el + '>'
    end

    if current_user and opts[:show_icons] and not @view_all and not get_plugin_api(:is_read).call(message, current_user).blank?
      html << "<span class=\"message-icons\">"
      html << button_to(unread_cf_message_path(thread, message), params: std_args, class: 'icon-message unread', title: t('plugins.mark_read.mark_unread')) do
        ''
      end
      html << "</span>"
    end


    if opts[:first] and current_forum.blank?
      html << "  " + link_to(thread.forum.short_name, cf_forum_path(thread.forum), class: 'thread-forum-plate') + "\n"
    end

    if opts[:show_icons]
      html << ' <span class="votes" title="' + t('messages.votes', num: message.score) + '">' + (message.score).to_s + '</span>'
    end

    if opts[:first]
      if opts[:show_icons]
        html << "<span class=\"num-infos\"><span class=\"num-msgs\" title=\"" + t("messages.num_messages", num: thread.messages.length) + "\">" + thread.messages.length.to_s + "</span>"
        unless thread.attribs[:msgs].blank?
          html << "<span class=\"num-unread\" title=\"" + t("plugins.mark_read.num_unread", num: thread.attribs[:msgs][:unread]) + "\">" + thread.attribs[:msgs][:unread].to_s + "</span>"
        end
        html << "</span>"
      end

      html << " <h2>" + link_to(message.subject, cf_message_path(thread, message)) + "</h2>"
    else
      if thread.thread_id and message.message_id
        if (opts[:hide_repeating_subjects] and message.subject_changed?) or not opts[:hide_repeating_subjects]
          html << "  <h3>" + link_to(message.subject, cf_message_path(thread, message)) + "</h3>"
        end
      else
        html << "  <h3>" + message.subject + "</h3>"
      end
    end

    html << %q{
  <div class="details">
      }

    html << " " + %q{
      <span class="author">}

    if message.user_id
      html << "<span class=\"registered-user"
      if not message.message_id == thread.message.message_id and message.user_id == thread.message.user_id
        html << " original-poster"
      end
      html << "\">" + link_to(image_tag(message.owner.avatar(:thumb), class: 'avatar'), user_path(message.owner), title: t('messages.user_link', user: message.owner.username), class: 'user-link') + " "
    else
      if not message.message_id == thread.message.message_id and not message.uuid.blank? and message.uuid == thread.message.uuid
        html << '<span class="icon-message original-poster" title="' + t('messages.original_poster') + '"> </span>'
      end
    end
    html << encode_entities(message.author)
    html << '</span>' if message.user_id

    if not opts[:tree] and (not message.email.blank? or not message.homepage.blank?)
      html << ' <span class="author-infos">'
      html << ' ' + link_to('', 'mailto:' + message.email, class: 'author-email') if not message.email.blank?
      html << ' ' + link_to('', message.homepage, class: 'author-homepage') if not message.homepage.blank?
      html << "</span>"
    end

    if current_user and (current_user.admin? or (current_forum and current_user.moderate?(current_forum))) and @view_all
      if not message.ip.blank?
        html << " <span class=\"admin-infos ip\">" + message.ip + "</span>"
      end
      if not message.uuid.blank?
        html << " <span class=\"admin-infos uuid\">" + message.uuid + "</span>"
      end
    end

    html << "</span>
      "

    text = "<time datetime=\"" + message.created_at.strftime("%FT%T%:z") + '">' +
           encode_entities(l(message.created_at, format: opts[:tree] ?
                                                   date_format("date_format_index") :
                                                   date_format("date_format_post"))) +
           "</time>"

    if thread.thread_id and message.message_id
      html << link_to(cf_message_path(thread, message)) do
        text.html_safe
      end
    else
      html << text.html_safe
    end

    unless message.tags.blank?
      html << %q{

    <ul class="cf-tags-list">}

      message.tags.each do |t|
        html << "<li class=\"cf-tag\">" + link_to(t.tag_name, tag_path(thread.forum.slug, t)) + "</li>"
      end

      html << "</ul>"
    end

    if opts[:show_votes]
      html << ' <span class="votes" title="' +
        t('messages.votes', num: message.score) +
        '">' +
        t('messages.votes', num: message.score) +
        '</span>'
    end


    html << %q{
  </div>
</header>}

    html.html_safe
  end

  def message_tree(thread, messages, opts = {})
    opts = {prev_deleted: false, show_icons: false, id: true,
            hide_repeating_subjects: false}.merge(opts)

    html = "<ol>\n"
    messages.each do |message|
      classes = []

      html << "<li"
      html << " class=\"" + classes.join(" ") + "\"" unless classes.blank?
      html << ">"
      html << message_header(thread, message, first: false,
                             prev_deleted: opts[:prev_deleted],
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects])
      html << message_tree(thread, message.messages, first: false,
                           prev_deleted: message.deleted?,
                           show_icons: opts[:show_icons],
                           id: opts[:id],
                           hide_repeating_subjects: opts[:hide_repeating_subjects]) unless message.messages.blank?
      html << "</li>"
    end

    html << "\n</ol>"

    html.html_safe
  end
end

# eof
