# -*- coding: utf-8 -*-

class MarkReadPlugin < Plugin
  def initialize(*args)
    super(*args)

    @cache = {}

    register_plugin_api :mark_read do |message, user|
      mark_read(message, user)
    end
    register_plugin_api :is_read do |message, user|
      is_read(message, user)
    end
  end

  def is_read(message, user)
    return if user.blank?

    message = [message] unless message.is_a?(Array)
    message = message.map {|m| m.is_a?(CfMessage) ? m.message_id : m.to_i}

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

    read_messages = []

    result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + message.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      m = row['message_id'].to_i
      read_messages << m
      new_cache[m] = true
    end

    @cache[user_id] ||= {}
    @cache[user_id] = @cache[user_id].merge(new_cache)

    read_messages
  end

  def mark_read(message, user)
    return if user.blank?
    message = [message] unless message.is_a?(Array)

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", "

    message.each do |m|
      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    message
  end

  def show_threadlist(threads)
    return unless current_user

    ids = []
    msgs = {}

    new_cache = {}

    threads.each do |t|
      num_msgs = 0

      t.messages.each do |m|
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

    @cache[current_user.user_id] ||= {}
    @cache[current_user.user_id] = @cache[current_user.user_id].merge(new_cache)
  end

  def show_thread(thread, message = nil)
    return unless current_user

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
    thread.messages.each do |m|
      m.attribs['visited'] = true

      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    check_thread(thread)
  end

  def show_message(thread, message)
    return unless current_user

    begin
      CfMessage.connection.execute("INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
    rescue ActiveRecord::RecordNotUnique
    end

    check_thread(thread)
  end

  private
  def check_thread(thread)
    ids = []
    msgs = {}

    thread.messages.each do |m|
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
  mr_plugin = MarkReadPlugin.new(app_controller)

  app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, mr_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_THREAD, mr_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_MESSAGE, mr_plugin)
end

# eof
