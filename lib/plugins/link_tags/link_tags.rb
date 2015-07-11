# -*- coding: utf-8 -*-

class LinkTagsPlugin < Plugin
  def to_shallow(msgs, ary)
    msgs.each do |m|
      ary << m
      to_shallow(m.messages, ary) unless m.messages.blank?
    end
  end

  def top_link
    '<link rel="top" href="' + cf_forum_path(current_forum || '/all') + '" title="' + encode_entities(current_forum ? current_forum.name : 'All Forums') + '">'
  end

  def first_link(thread, msgs)
    '<link rel="first" href="' + cf_message_path(thread, msgs[0]) + '" title="' + t('plugins.link_tags.first_msg') + '">'
  end

  def last_link(thread, msgs)
    '<link rel="last" href="' + cf_message_path(thread, msgs[-1]) + '" title="' + t('plugins.link_tags.last_msg') + '">'
  end

  def prev_link(thread, msgs, message)
    msgs.each_with_index do |m, i|
      if m.message_id == message.message_id
        return '<link rel="prev" href="' + cf_message_path(thread, msgs[i - 1]) + '" title="' + t('plugins.link_tags.prev_msg') + '">' if i > 0
        return ''
      end
    end

    ''
  end

  def next_link(thread, msgs, message)
    msgs.each_with_index do |m, i|
      if m.message_id == message.message_id
        return '<link rel="next" href="' + cf_message_path(thread, msgs[i + 1]) + '" title="' + t('plugins.link_tags.next_msg') + '">' if msgs[i + 1] # TODO: Localize
        return ''
      end
    end

    ''
  end

  def show_threadlist(threads)
    set('link_tags', top_link.html_safe)
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist
  alias show_interesting_messagelist show_threadlist

  def show_thread(thread, message = nil, votes = nil)
    msgs = []
    to_shallow([thread.message], msgs)

    html = top_link
    html << "\n" + first_link(thread, msgs)
    html << "\n" + last_link(thread, msgs)
    html << "\n" + next_link(thread, msgs, message)
    html << "\n" + prev_link(thread, msgs, message)

    set('link_tags', html.html_safe)
  end

  def show_message(thread, message, votes)
    msgs = []
    to_shallow([thread.message], msgs)

    html = top_link
    html << "\n" + first_link(thread, msgs)
    html << "\n" + last_link(thread, msgs)
    html << "\n" + next_link(thread, msgs, message)
    html << "\n" + prev_link(thread, msgs, message)

    set('link_tags', html.html_safe)
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  lt_plugin = LinkTagsPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST,
                  lt_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD,
                  lt_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE,
                  lt_plugin)

  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST,
                  lt_plugin)
  app_controller.notification_center.
    register_hook(CfThreads::InvisibleController::SHOW_INVISIBLE_THREADLIST,
                  lt_plugin)

  app_controller.notification_center.
    register_hook(CfMessages::InterestingController::SHOW_INTERESTING_MESSAGELIST,
                  lt_plugin)
end

# eof
