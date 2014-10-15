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
    thread = [thread] unless thread.is_a?(Array)

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
    thread = [thread] unless thread.is_a?(Array)
    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }

    sql = "DELETE FROM intesting_threads WHERE user_id =  " + current_user.user_id.to_s +
      " AND thread_id IN (" + thread.join(',') + ")"

    CfMessage.connection.execute(sql + t.thread_id.to_s + ")")

    true
  end

  def is_interesting(thread, user)
    return if user.blank?

    thread = [thread] unless thread.is_a?(Array)
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

  def show_thread(thread, message, votes)
  end

  def show_message(thread, message, votes)
  end
  # def show_thread(thread, message = nil, votes = nil)
  #   return unless current_user

  #   mark_read_moment = uconf('mark_read_moment', 'before_render')

  #   check_thread(thread) if mark_read_moment == 'after_render'

  #   sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
  #   thread.sorted_messages.each do |m|
  #     begin
  #       CfMessage.connection.execute(sql + m.message_id.to_s + ")")
  #     rescue ActiveRecord::RecordNotUnique
  #     end
  #   end

  #   check_thread(thread) if mark_read_moment == 'before_render'
  # end

  # def show_message(thread, message, votes)
  #   return unless current_user
  #   mark_read_moment = uconf('mark_read_moment', 'before_render')

  #   check_thread(thread) if mark_read_moment == 'after_render'

  #   begin
  #     CfMessage.connection.execute("INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
  #   rescue ActiveRecord::RecordNotUnique
  #   end

  #   check_thread(thread) if mark_read_moment == 'before_render'
  # end

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
end

# eof
