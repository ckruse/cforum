# -*- coding: utf-8 -*-

class LinkTagsPlugin < Plugin
  def top_link
    '<link rel="top" href="' + cf_forum_path(current_forum || '/all') + '" title="' + encode_entities(current_forum ? current_forum.name : 'All Forums') + '">'
  end

  def first_link(thread)
    '<link rel="first" href="' + cf_message_path(thread, thread.message) + '" title="First Message">' # TODO: Localize
  end

  def last_link(thread)
    '<link rel="last" href="' + cf_message_path(thread, thread.messages[-1]) + '" title="Last Message">' # TODO: Localize
  end

  def prev_link(thread, message)
    thread.messages.each_with_index do |m, i|
      return '<link rel="next" href="' + cf_message_path(thread, thread.messages[i-1]) + '" title="Previous Message">' if m.message_id == message.message_id and m.message_id != thread.message.message_id # TODO: Localize
    end

    ''
  end

  def next_link(thread, message)
    thread.messages.each_with_index do |m, i|
      return '<link rel="next" href="' + cf_message_path(thread, thread.messages[i+1]) + '" title="Next Message">' if m.message_id == message.message_id and m != thread.messages.last # TODO: Localize
    end

    ''
  end

  def show_threadlist(threads)
    set('link_tags', top_link.html_safe)
  end

  def show_thread(thread, message = nil)
    html = top_link
    html << "\n" + first_link(thread)
    html << "\n" + last_link(thread)
    html << "\n" + next_link(thread, message) if message.message_id != thread.messages[-1].message_id
    html << "\n" + prev_link(thread, message) if message.message_id != thread.message.message_id

    set('link_tags', html.html_safe)
  end

  def show_message(thread, message)
    html = top_link
    html << "\n" + first_link(thread)
    html << "\n" + last_link(thread)
    html << "\n" + next_link(thread, message) if message.message_id != thread.messages[-1].message_id
    html << "\n" + prev_link(thread, message) if message.message_id != thread.message.message_id

    set('link_tags', html.html_safe)
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  lt_plugin = LinkTagsPlugin.new(app_controller)

  app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, lt_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_THREAD, lt_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_MESSAGE, lt_plugin)
end

# eof