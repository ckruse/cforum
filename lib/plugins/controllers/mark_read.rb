# -*- coding: utf-8 -*-

class MarkRead < Plugin
  def initialize(*args)
    super(*args)

    register_plugin_api :mark_read { |message| mark_read(message) }
    register_plugin_api :is_read { |message| is_read(message) }
  end

  def is_read(message)
    return unless current_user
    message = [message] unless message.is_a?(Array)
    message = message.map {|m| m.is_a?(CfMessage) ? m.message_id : m.to_i}

    read_messages = []

    result = CfMessage.connection.execute("SELECT message_id FROM cforum.read_messages WHERE message_id IN (" + message.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
    result.reach do |row|
      read_messages << row['message_id'].to_i
    end
  end

  def mark_read(message)
    return unless current_user
    message = [message] unless message.is_a?(Array)

    sql = "INSERT INTO cforum.read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "

    message.each do |m|
      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end

  def show_threadlist(threads)
    return unless current_user

    ids = []
    msgs = {}

    threads.each do |t|
      t.messages.each do |m|
        ids << m.message_id
        msgs[m.message_id.to_s] = m
      end
    end

    result = CfMessage.connection.execute("SELECT message_id FROM cforum.read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
    result.each do |row|
      msgs[row['message_id']].attribs['visited'] = true if msgs[row['message_id']]
    end
  end

  def show_thread(thread)
    return unless current_user

    sql = "INSERT INTO cforum.read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
    thread.messages.each do |m|
      m.attribs['visited'] = true

      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end

  def show_message(thread, message)
    return unless current_user

    begin
      CfMessage.connection.execute("INSERT INTO cforum.read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
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

    result = CfMessage.connection.execute("SELECT message_id FROM cforum.read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
    result.each do |row|
      msgs[row['message_id']].attribs['visited'] = true if msgs[row['message_id']]
    end
  end
end

mr = MarkRead.new(self)

notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, mr)
notification_center.register_hook(CfThreadsController::SHOW_THREAD, mr)
notification_center.register_hook(CfMessagesController::SHOW_MESSAGE, mr)

# eof