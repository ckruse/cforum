# -*- coding: utf-8 -*-

module LinkTagsHelper
  def to_shallow(msgs, ary)
    msgs.each do |m|
      ary << m
      to_shallow(m.messages, ary) unless m.messages.blank?
    end
  end

  def top_link
    '<link rel="index" href="' + forum_path(current_forum) + '" title="' +
      encode_entities(current_forum ? current_forum.name : I18n.t('forums.all_forums')) + '">'
  end

  def first_link(thread, msgs)
    '<link rel="first" href="' + message_path(thread, msgs[0]) + '" title="' + t('plugins.link_tags.first_msg') + '">'
  end

  def last_link(thread, msgs)
    '<link rel="last" href="' + message_path(thread, msgs[-1]) + '" title="' + t('plugins.link_tags.last_msg') + '">'
  end

  def prev_link(thread, msgs, message)
    msgs.each_with_index do |m, i|
      if m.message_id == message.message_id
        return '<link rel="prev" href="' + message_path(thread, msgs[i - 1]) + '" title="' + t('plugins.link_tags.prev_msg') + '">' if i > 0
        return ''
      end
    end

    ''
  end

  def next_link(thread, msgs, message)
    msgs.each_with_index do |m, i|
      if m.message_id == message.message_id
        return '<link rel="next" href="' + message_path(thread, msgs[i + 1]) + '" title="' + t('plugins.link_tags.next_msg') + '">' if msgs[i + 1] # TODO: Localize
        return ''
      end
    end

    ''
  end

  def thread_list_link_tags
    @link_tags = top_link.html_safe
  end

  def show_thread_link_tags(thread, message = nil)
    msgs = []
    to_shallow([thread.message], msgs)

    html = top_link
    html << "\n" + first_link(thread, msgs)
    html << "\n" + last_link(thread, msgs)
    html << "\n" + next_link(thread, msgs, message)
    html << "\n" + prev_link(thread, msgs, message)

    @link_tags = html.html_safe
  end

  def show_message_link_tags(thread, message)
    msgs = []
    to_shallow([thread.message], msgs)

    html = top_link
    html << "\n" + first_link(thread, msgs)
    html << "\n" + last_link(thread, msgs)
    html << "\n" + next_link(thread, msgs, message)
    html << "\n" + prev_link(thread, msgs, message)

    @link_tags = html.html_safe
  end
end

# eof
