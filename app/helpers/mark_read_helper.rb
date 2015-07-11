# -*- coding: utf-8 -*-

module MarkReadHelper
  def is_read(user, message)
    return if user.blank? || message.blank?

    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map {|m| m.is_a?(CfMessage) ? m.message_id : m.to_i}

    return if message.blank?

    user_id = user.is_a?(CfUser) ? user.user_id : user

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
end

# eof
