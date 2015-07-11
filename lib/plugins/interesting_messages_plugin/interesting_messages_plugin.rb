# -*- coding: utf-8 -*-

class InterestingMessagesPlugin < Plugin
  def show_threadlist(threads)
    return unless current_user

    ids = []
    messages_map = {}
    new_cache = {}

    threads.each do |t|
      t.messages.each do |m|
        messages_map[m.message_id] = [m, t]
        new_cache[m.message_id] = false
        ids << m.message_id
      end
    end

    if not ids.blank?
      result = CfMessage.connection.execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id'].to_i] = true

        if messages_map[row['message_id'].to_i]
          messages_map[row['message_id'].to_i].first.attribs['classes'] << 'interesting'
          messages_map[row['message_id'].to_i].first.attribs[:is_interesting] = true
          messages_map[row['message_id'].to_i].second.attribs['classes'] << 'has-interesting'
          messages_map[row['message_id'].to_i].second.attribs[:has_interesting] = true
        end
      end
    end

    @app_controller.merge_cached_entry(:interesting, current_user.user_id, new_cache)
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist

  def show_thread(thread, message = nil, votes = nil)
    return if current_user.blank?
    if check_messages(thread.messages)
      thread.attribs['classes'] << 'has-interesting'
      thread.attribs[:has_interesting] = true
    end
  end

  alias show_message show_thread
  alias show_new_message show_thread

  def show_interesting_messagelist(messages)
    return if current_user.blank?
    check_messages(messages)
  end

  def check_messages(messages)
    ids = []
    msgs = {}
    new_cache = {}
    had_all = true
    had_one = false
    cache = @app_controller.get_cached_entry(:interesting, current_user.user_id) || {}

    messages.each do |m|
      ids << m.message_id
      msgs[m.message_id.to_s] = m
      new_cache[m.message_id] = false

      if not cache.has_key?(m.message_id)
        had_all = false
      elsif cache[m.message_id]
        m.attribs['classes'] << 'interesting'
        m.attribs[:is_interesting] = true
        had_one = true
      end
    end

    unless had_all
      result = CfMessage.connection.execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id'].to_i] = true
        msgs[row['message_id']].attribs['classes'] << 'interesting' if msgs[row['message_id']]
        msgs[row['message_id']].attribs[:is_interesting] = true
        had_one = true
      end

      @app_controller.set_cached_entry(:interesting, current_user.user_id, new_cache)
    end

    return had_one
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  interesting_threads = InterestingMessagesPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST, interesting_threads)
  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST, interesting_threads)
  app_controller.notification_center.
    register_hook(CfThreads::InvisibleController::SHOW_INVISIBLE_THREADLIST,
                  interesting_threads)

  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_NEW_MESSAGE, interesting_threads)

  app_controller.notification_center.
    register_hook(CfMessages::InterestingController::SHOW_INTERESTING_MESSAGELIST, interesting_threads)
end

# eof
