# -*- coding: utf-8 -*-

class InterestingThreadsPlugin < Plugin
  def initialize(*args)
    super(*args)

    @cache = {}

    register_plugin_api :mark_interesting do |thread, user|
      mark_interesting(thread, user)
    end
    register_plugin_api :mark_boring do |thread, user|
      mark_boring(thread, user)
    end
    register_plugin_api :is_interesting do |thread, user|
      is_interesting(thread, user)
    end
  end

  def mark_interesting(thread, user)
    return if user.blank?
    thread = [thread] if not thread.is_a?(Array) and not thread.is_a?(ActiveRecord::Relation)

    sql = "INSERT INTO intesting_threads (user_id, thread_id) VALUES (" + user.user_id.to_s + ", "

    thread.each do |t|
      begin
        CfMessage.connection.execute(sql + t.thread_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    thread
  end

  def mark_boring(thread, user)
    return if user.blank?
    thread = [thread] if not thread.is_a?(Array) and not thread.is_a?(ActiveRecord::Relation)
    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }

    sql = "DELETE FROM intesting_threads WHERE user_id =  " + current_user.user_id.to_s +
      " AND thread_id IN (" + thread.join(',') + ")"

    CfMessage.connection.execute(sql + t.thread_id.to_s + ")")

    true
  end

  def is_interesting(thread, user)
    return if user.blank?

    thread = [thread] if not thread.is_a?(Array) and not thread.is_a?(ActiveRecord::Relation)
    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }

    user_id = user.is_a?(CfUser) ? user.user_id : user

    new_cache = {}

    if @cache[user_id]
      has_all = true
      retval = []

      thread.each do |t|
        if not @cache[user_id].has_key?(t)
          has_all = false
        else
          retval << t if @cache[user_id][t]
        end
        new_cache[t] = false
      end

      return retval if has_all
    end

    intesting_threads = []

    result = CfThread.connection.
      execute("SELECT thread_id FROM interesting_threads WHERE thread_id IN (" +
              thread.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      t = row['thread_id'].to_i
      intesting_threads << t
      new_cache[t] = true
    end

    @cache[user_id] ||= {}
    @cache[user_id] = @cache[user_id].merge(new_cache)

    intesting_threads
  end

  def show_threadlist(threads)
    return unless current_user

    ids = []
    threads_map = {}
    new_cache = {}

    threads.each do |t|
      threads_map[t.thread_id] = t
      new_cache[t.thread_id] = false
      ids << t.thread_id
    end

    if not ids.blank?
      result = CfThread.connection.execute("SELECT thread_id FROM interesting_threads WHERE thread_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        new_cache[row['thread_id'].to_i] = true

        if threads_map[row['thread_id'].to_i]
          threads_map[row['thread_id'].to_i].attribs['classes'] << 'interesting'
        end
      end
    end

    @cache[current_user.user_id] ||= {}
    @cache[current_user.user_id] = @cache[current_user.user_id].merge(new_cache)
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist

  def show_thread(thread, message, votes)
  end

  def show_message(thread, message, votes)
  end

  private
  def check_thread(thread)
    ids = []
    msgs = {}

    thread.sorted_messages.each do |m|
      ids << m.message_id
      msgs[m.message_id.to_s] = m
    end

    result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
    result.each do |row|
      msgs[row['message_id']].attribs['classes'] << 'visited' if msgs[row['message_id']]
    end
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  interesting_threads = InterestingThreadsPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, interesting_threads)
  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST, interesting_threads)
  app_controller.notification_center.
    register_hook(InvisibleThreadsPluginController::SHOW_INVISIBLE_THREADLIST,
                  interesting_threads)
end

# eof
