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
    return if user.blank? || message.blank?

    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
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
    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)

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

    @cache[current_user.user_id] ||= {}
    @cache[current_user.user_id] = @cache[current_user.user_id].merge(new_cache)
  end

  def show_thread(thread, message = nil, votes = nil)
    return if current_user.blank? or @app_controller.is_prefetch

    mark_read_moment = uconf('mark_read_moment', 'before_render')

    check_thread(thread) if mark_read_moment == 'after_render'

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
    thread.sorted_messages.each do |m|
      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    check_thread(thread) if mark_read_moment == 'before_render'
  end

  def show_message(thread, message, votes)
    return if current_user.blank? or @app_controller.is_prefetch
    mark_read_moment = uconf('mark_read_moment', 'before_render')

    check_thread(thread) if mark_read_moment == 'after_render'

    begin
      CfMessage.connection.execute("INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
    rescue ActiveRecord::RecordNotUnique
    end

    check_thread(thread) if mark_read_moment == 'before_render'
  end

  def show_forumlist(counts, activities, admin = false)
    return if current_user.blank? or activities.values.blank?

    messages = activities.values
    ids = messages.map { |a| a.message_id }
    result = CfMessage.connection.execute("SELECT message_id FROM read_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)

    result.each do |row|
      a = messages.find { |m| m.message_id == row['message_id'].to_i }
      a.attribs['classes'] << 'visited' if a
    end

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
  mr_plugin = MarkReadPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST, mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, mr_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, mr_plugin)
  app_controller.notification_center.
    register_hook(CfForumsController::SHOW_FORUMLIST, mr_plugin)
end

# eof
