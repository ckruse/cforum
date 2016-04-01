# -*- coding: utf-8 -*-

module InterestingHelper
  def mark_interesting(user, message)
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

  def mark_boring(user, message)
    return if user.blank?
    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(CfMessage) ? m.message_id : m.to_i }

    sql = "DELETE FROM intesting_messages WHERE user_id =  " + current_user.user_id.to_s +
      " AND message_id IN (" + message.join(',') + ")"

    CfMessage.connection.execute(sql)

    true
  end

  def is_interesting(user, message)
    return if user.blank?

    message = [message] if not message.is_a?(Array) and not message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(CfMessage) ? m.message_id : m.to_i }

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:interesting, user_id) || {}

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

    intesting_messages = []

    result = CfMessage.connection.
             execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" +
                     message.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      m = row['thread_id'].to_i
      intesting_messages << m
      new_cache[m] = true
    end

    merge_cached_entry(:interesting, usser_id, new_cache)

    intesting_messages
  end

  def mark_threads_interesting(threads, user = current_user)
    return if user.blank?

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
      result = CfMessage.connection.execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + user.user_id.to_s)
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

    merge_cached_entry(:interesting, user.user_id, new_cache)
  end

  def mark_messages_interesting(messages, user = current_user)
    ids = []
    msgs = {}
    new_cache = {}
    had_all = true
    had_one = false
    cache = get_cached_entry(:interesting, user.user_id) || {}

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
      result = CfMessage.connection.execute("SELECT message_id FROM interesting_messages WHERE message_id IN (" + ids.join(", ") + ") AND user_id = " + user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id'].to_i] = true
        msgs[row['message_id']].attribs['classes'] << 'interesting' if msgs[row['message_id']]
        msgs[row['message_id']].attribs[:is_interesting] = true
        had_one = true
      end

      set_cached_entry(:interesting, user.user_id, new_cache)
    end

    return had_one
  end
end

# eof
