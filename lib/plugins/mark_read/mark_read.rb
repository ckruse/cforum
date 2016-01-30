# -*- coding: utf-8 -*-

class MarkReadPlugin < Plugin
  def initialize(*args)
    super(*args)
  end

  def show_threadlist(threads)
    return if current_user.blank?

    ids = []
    msgs = {}

    new_cache = {}

    threads.each do |t|
      num_msgs = 0

      t.sorted_messages.each do |m|
        ids << m.message_id
        new_cache[m.message_id] = false
        msgs[m.message_id.to_s] = [m, t]
        num_msgs += 1
      end

      t.attribs[:msgs] = {all: num_msgs, unread: num_msgs}
    end

    if not ids.blank?
      result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id'].to_i] = true

        if msgs[row['message_id']]
          msgs[row['message_id']][0].attribs['classes'] << 'visited'
          msgs[row['message_id']][1].attribs[:msgs][:unread] -= 1
        end
      end
    end

    @app_controller.merge_cached_entry(:mark_read, current_user.user_id, new_cache)
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist

  def show_thread(thread, message = nil, votes = nil)
    return if current_user.blank? or @app_controller.is_prefetch

    check_thread(thread)
    cache = @app_controller.get_cached_entry(:mark_read, current_user.user_id) || {}

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
    thread.sorted_messages.each do |m|
      next if cache[m.message_id]

      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
        cache[m.message_id] = true
      rescue ActiveRecord::RecordNotUnique
      end
    end

    @app_controller.publish('thread:read', {type: 'thread', thread: thread},
                            '/users/' + current_user.user_id.to_s)

    @app_controller.set_cached_entry(:mark_read, current_user.user_id, cache)
  end

  def show_message(thread, message, votes)
    return if current_user.blank? or @app_controller.is_prefetch
    cache = @app_controller.get_cached_entry(:mark_read, current_user.user_id) || {}

    check_thread(thread)

    if not cache[message.message_id]
      begin
        CfMessage.connection.execute("INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
        cache[message.message_id] = true
      rescue ActiveRecord::RecordNotUnique
      end
    end

    @app_controller.publish('message:read', {type: 'message', thread: thread, message: message},
                            '/users/' + current_user.user_id.to_s)

    @app_controller.set_cached_entry(:mark_read, current_user.user_id, cache)
  end
  alias show_new_message show_message

  def show_interesting_messagelist(messages)
    return if current_user.blank?
    check_messages(messages)
  end

  def show_forumlist(threads, activities, admin = false)
    return if current_user.blank? or activities.values.blank?

    messages = []
    threads.each do |thread|
      messages += thread.messages.select { |m| m.deleted == false }
    end

    ids = messages.map { |a| a.message_id }
    result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)

    result.each do |row|
      a = messages.find { |m| m.message_id == row['message_id'].to_i }
      a.attribs['classes'] << 'visited' if a
    end

  end

  private

  def check_thread(thread)
    check_messages(thread.messages)
  end

  def check_messages(messages)
    ids = []
    msgs = {}

    messages.each do |m|
      ids << m.message_id
      msgs[m.message_id.to_s] = m
    end

    unless ids.blank?
      result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        msgs[row['message_id']].attribs['classes'] << 'visited' if msgs[row['message_id']]
      end
    end
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  mr_plugin = MarkReadPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST, mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_NEW_MESSAGE, mr_plugin)
  app_controller.notification_center.
    register_hook(CfForumsController::SHOW_FORUMLIST, mr_plugin)
  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST, mr_plugin)
  app_controller.notification_center.
    register_hook(CfThreads::InvisibleController::SHOW_INVISIBLE_THREADLIST,
                  mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessages::InterestingController::SHOW_INTERESTING_MESSAGELIST,
                  mr_plugin)
end

# eof
