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
    index = thread.sorted_messages.find_index { |m| m.message_id == message.message_id }
    return '' if index.nil? || index.zero?
    '<link rel="prev" href="' + message_path(thread, thread.sorted_messages[index - 1]) +
      '" title="' + t('plugins.link_tags.prev_msg') + '">'
  end

  def next_link(thread, message)
    index = thread.sorted_messages.find_index { |m| m.message_id == message.message_id }
    return '' if index.nil? || thread.sorted_messages[index + 1].blank?
    '<link rel="next" href="' + message_path(thread, thread.sorted_messages[index + 1]) +
      '" title="' + t('plugins.link_tags.next_msg') + '">'
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
    html = top_link
    html << "\n" + first_link(thread)
    html << "\n" + last_link(thread)
    html << "\n" + next_link(thread, message)
    html << "\n" + prev_link(thread, message)

    @link_tags = html.html_safe
  end
end

# eof
