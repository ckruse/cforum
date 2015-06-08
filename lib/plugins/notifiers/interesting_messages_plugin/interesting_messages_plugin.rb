# -*- coding: utf-8 -*-

class InterestingMessagesPlugin < Plugin
  def initialize(*args)
    super(*args)

    @cache = {}

    register_plugin_api :mark_interesting do |message, user|
      mark_interesting(message, user)
    end
    register_plugin_api :mark_boring do |message, user|
      mark_boring(message, user)
    end
    register_plugin_api :is_interesting do |message, user|
      is_interesting(message, user)
    end
  end

  def mark_interesting(message, user)
    return if user.blank?
    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)

    sql = "INSERT INTO intesting_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", "

    message.each do |m|
      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    thread
  end

  def mark_boring(message, user)
    return if user.blank?
    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(CfMessage) ? m.message_id : m.to_i }

    sql = "DELETE FROM intesting_messages WHERE user_id =  " + current_user.user_id.to_s +
      " AND message_id IN (" + message.join(',') + ")"

    CfMessage.connection.execute(sql)

    true
  end

  def is_interesting(message, user)
    return if user.blank?

    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(CfMessage) ? m.message_id : m.to_i }

    user_id = user.is_a?(CfUser) ? user.user_id : user

    new_cache = {}

    if @cache[user_id]
      has_all = true
      retval = []

      message.each do |m|
        if not @cache[user_id].has_key?(m)
          has_all = false
        else
          retval << m if @cache[user_id][m]
        end
        new_cache[m] = false
      end

      return retval if has_all
    end

    intesting_messages = []

    result = CfMessage.connection.
             execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" +
                     message.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      m = row['thread_id'].to_i
      intesting_messages << m
      new_cache[m] = true
    end

    @cache[user_id] ||= {}
    @cache[user_id] = @cache[user_id].merge(new_cache)

    intesting_messages
  end

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
        end
      end
    end

    @cache[current_user.user_id] ||= {}
    @cache[current_user.user_id] = @cache[current_user.user_id].merge(new_cache)
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist

  def show_thread(thread, message = nil, votes = nil)
    return if current_user.blank?
    if check_messages(thread.messages)
      thread.attribs['classes'] << 'has-interesting'
    end
  end

  alias show_message show_thread
  alias show_new_message show_thread

  def check_messages(messages)
    ids = []
    msgs = {}
    new_cache = {}
    had_all = true
    had_one = false
    @cache[current_user.user_id] ||= {}

    messages.each do |m|
      ids << m.message_id
      msgs[m.message_id.to_s] = m
      new_cache[m.message_id] = false

      if not @cache[current_user.user_id].has_key?(m.message_id)
        had_all = false
      elsif @cache[current_user.user_id][m.message_id]
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

      @cache[current_user.user_id] = new_cache
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
    register_hook(InvisibleThreadsPluginController::SHOW_INVISIBLE_THREADLIST,
                  interesting_threads)

  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, interesting_threads)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_NEW_MESSAGE, interesting_threads)
end

# eof
