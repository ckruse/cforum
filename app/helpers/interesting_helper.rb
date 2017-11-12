module InterestingHelper
  def mark_interesting(user, message)
    return if user.blank?
    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)

    sql = 'INSERT INTO intesting_messages (user_id, message_id) VALUES (' + user.user_id.to_s + ', '

    message.each do |m|
      begin
        Message.connection.execute(sql + m.message_id.to_s + ')')
      rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
      end
    end

    thread
  end

  def mark_boring(user, message)
    return if user.blank?
    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(Message) ? m.message_id : m.to_i }

    sql = 'DELETE FROM intesting_messages WHERE user_id =  ' + current_user.user_id.to_s +
          ' AND message_id IN (' + message.join(',') + ')'

    Message.connection.execute(sql)

    true
  end

  def interesting?(user, message)
    return if user.blank?

    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(Message) ? m.message_id : m.to_i }

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:interesting, user_id) || {}

    if cache
      has_all = true
      retval = []

      message.each do |m|
        if !cache.key?(m)
          has_all = false
        elsif cache[m]
          retval << m
        end
        new_cache[m] = false
      end

      return retval if has_all
    end

    intesting_messages = []

    result = Message.connection
               .execute('SELECT message_id FROM interesting_messages WHERE message_id IN (' +
                     message.join(', ') + ') AND user_id = ' + user_id.to_s)
    result.each do |row|
      m = row['thread_id']
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

    if ids.present?
      result = Message.connection.execute('SELECT message_id FROM interesting_messages WHERE message_id IN (' +
                                          ids.join(', ') + ') AND user_id = ' + user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id']] = true

        next unless messages_map[row['message_id']]
        messages_map[row['message_id']].first.attribs['classes'] << 'interesting'
        messages_map[row['message_id']].first.attribs[:is_interesting] = true
        messages_map[row['message_id']].second.attribs['classes'] << 'has-interesting'
        messages_map[row['message_id']].second.attribs[:has_interesting] = true
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
      msgs[m.message_id] = m
      new_cache[m.message_id] = false

      if !cache.key?(m.message_id)
        had_all = false
      elsif cache[m.message_id]
        m.attribs['classes'] << 'interesting'
        m.attribs[:is_interesting] = true
        had_one = true
      end
    end

    unless had_all
      result = Message.connection.execute('SELECT message_id FROM interesting_messages WHERE message_id IN (' +
                                          ids.join(', ') + ') AND user_id = ' + user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id']] = true
        msgs[row['message_id']].attribs['classes'] << 'interesting'
        msgs[row['message_id']].attribs[:is_interesting] = true
        had_one = true
      end

      set_cached_entry(:interesting, user.user_id, new_cache)
    end

    had_one
  end
end

# eof
