# -*- coding: utf-8 -*-

module MarkReadHelper
  def is_read(user, message)
    return if user.blank? || message.blank?

    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map {|m| m.is_a?(CfMessage) ? m.message_id : m.to_i}

    return if message.blank?

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:mark_read, user_id)

    if cache
      has_all = true
      retval = []

      message.each do |m|
        if not cache.has_key?(m)
          has_all = false
        else
          retval << m if cache[m]
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

    merge_cached_entry(:mark_read, user_id, new_cache)

    read_messages
  end

  def are_read(messages)
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

  def mark_read(user, message)
    return if user.blank?
    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", "
    cache = get_cached_entry(:mark_read, user_id) || {}

    message.each do |m|
      next if cache[m.message_id]

      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
        cache[m.message_id] = true
      rescue ActiveRecord::RecordNotUnique
      end
    end

    set_cached_entry(:mark_read, user_id, cache)

    message
  end

  def is_read_threadlist(threads)
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

    merge_cached_entry(:mark_read, current_user.user_id, new_cache)
  end

  def mark_thread_read(thread)
    return if current_user.blank? or is_prefetch

    are_read(thread.messages)
    cache = get_cached_entry(:mark_read, current_user.user_id) || {}

    sql = "INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", "
    thread.sorted_messages.each do |m|
      next if cache[m.message_id]

      begin
        CfMessage.connection.execute(sql + m.message_id.to_s + ")")
        cache[m.message_id] = true
      rescue ActiveRecord::RecordNotUnique
      end
    end

    publish('thread:read', {type: 'thread', thread: thread},
            '/users/' + current_user.user_id.to_s)

    set_cached_entry(:mark_read, current_user.user_id, cache)
  end

  def mark_message_read(thread, message)
    return if current_user.blank? or is_prefetch
    cache = get_cached_entry(:mark_read, current_user.user_id) || {}

    are_read(thread.messages)

    if not cache[message.message_id]
      begin
        CfMessage.connection.execute("INSERT INTO read_messages (user_id, message_id) VALUES (" + current_user.user_id.to_s + ", " + message.message_id.to_s + ")")
        cache[message.message_id] = true
      rescue ActiveRecord::RecordNotUnique
      end
    end

    publish('message:read', {type: 'message', thread: thread, message: message},
            '/users/' + current_user.user_id.to_s)

    set_cached_entry(:mark_read, current_user.user_id, cache)
  end

  def forum_list_read(threads, activities)
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
end

# eof
