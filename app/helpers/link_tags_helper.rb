# -*- coding: utf-8 -*-

module LinkTagsHelper
  def top_link
    '<link rel="index" href="' + forum_path(current_forum) + '" title="' +
      encode_entities(current_forum ? current_forum.name : I18n.t('forums.all_forums')) + '">'
  end

  def first_link(thread)
    '<link rel="first" href="' + message_path(thread, thread.sorted_messages[0]) +
      '" title="' + t('plugins.link_tags.first_msg') + '">'
  end

  def last_link(thread)
    '<link rel="last" href="' + message_path(thread, thread.sorted_messages[-1]) +
      '" title="' + t('plugins.link_tags.last_msg') + '">'
  end

  def prev_link(thread, message)
    thread.sorted_messages.each_with_index do |m, i|
      next if m.message_id != message.message_id

      if i > 0
        return '<link rel="prev" href="' + message_path(thread, thread.sorted_messages[i - 1]) +
               '" title="' + t('plugins.link_tags.prev_msg') + '">'
      end

      return ''
    end

    ''
  end

  def next_link(thread, message)
    thread.sorted_messages.each_with_index do |m, i|
      next if m.message_id != message.message_id

      if thread.sorted_messages[i + 1]
        return '<link rel="next" href="' + message_path(thread, thread.sorted_messages[i + 1]) +
               '" title="' + t('plugins.link_tags.next_msg') + '">'
      end

      return ''
    end

    ''
  end

  def thread_list_link_tags
    @link_tags = top_link.html_safe
  end

  def show_thread_link_tags(thread, message = nil)
    html = top_link
    html << "\n" + first_link(thread)
    html << "\n" + last_link(thread)
    html << "\n" + next_link(thread, message)
    html << "\n" + prev_link(thread, message)

    @link_tags = html.html_safe
  end

  def show_message_link_tags(thread, message)
    msgs = []
    to_shallow([thread.message], msgs)

    html = top_link
    html << "\n" + first_link(thread)
    html << "\n" + last_link(thread)
    html << "\n" + next_link(thread, message)
    html << "\n" + prev_link(thread, message)

    @link_tags = html.html_safe
  end
end

# eof
