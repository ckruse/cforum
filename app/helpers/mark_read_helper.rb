module MarkReadHelper
  def message_read?(user, message)
    return if user.blank? || message.blank?

    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(Message) ? m.message_id : m.to_i }

    return if message.blank?

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:mark_read, user_id)

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

    read_messages = []

    result = Message.connection.execute('SELECT message_id FROM read_messages WHERE message_id IN (' +
                                        message.join(', ') + ') AND user_id = ' + user_id.to_s)
    result.each do |row|
      m = row['message_id']
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
      msgs[m.message_id] = m
    end

    return if ids.blank?

    result = Message.connection.execute('SELECT message_id FROM read_messages WHERE message_id IN (' +
                                        ids.join(', ') + ') AND user_id = ' + current_user.user_id.to_s)
    result.each do |row|
      msgs[row['message_id']].attribs['classes'] << 'visited'
    end
  end

  def mark_read(user, message)
    return if user.blank?
    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)

    sql = 'INSERT INTO read_messages (user_id, message_id) VALUES (' + user.user_id.to_s + ', '
    cache = get_cached_entry(:mark_read, user_id) || {}

    Message.transaction(requires_new: true) do
      message.each do |m|
        next if cache[m.message_id]

        begin
          Message.transaction(requires_new: true) do
            Message.connection.execute(sql + m.message_id.to_s + ')')
          end
          cache[m.message_id] = true
        rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
        end
      end
    end

    set_cached_entry(:mark_read, user_id, cache)

    message
  end

  def read_threadlist?(threads)
    return if current_user.blank?

    ids = []
    msgs = {}

    new_cache = {}

    threads.each do |t|
      num_msgs = 0

      t.sorted_messages.each do |m|
        ids << m.message_id
        new_cache[m.message_id] = false
        msgs[m.message_id] = [m, t]
        num_msgs += 1
      end

      t.attribs[:msgs] = { all: num_msgs, unread: num_msgs }
    end

    if ids.present?
      result = Message.connection.execute('SELECT message_id FROM read_messages WHERE message_id IN (' +
                                          ids.join(', ') + ') AND user_id = ' + current_user.user_id.to_s)
      result.each do |row|
        new_cache[row['message_id']] = true

        if msgs[row['message_id']]
          msgs[row['message_id']][0].attribs['classes'] << 'visited'
          msgs[row['message_id']][1].attribs[:msgs][:unread] -= 1
        end
      end
    end

    merge_cached_entry(:mark_read, current_user.user_id, new_cache)
  end

  def mark_thread_read(thread)
    return if current_user.blank? || prefetch?

    are_read(thread.messages)
    cache = get_cached_entry(:mark_read, current_user.user_id) || {}

    sql = 'INSERT INTO read_messages (user_id, message_id) VALUES (' + current_user.user_id.to_s + ', '

    Message.transaction(requires_new: true) do
      thread.sorted_messages.each do |m|
        next if cache[m.message_id]

        begin
          Message.transaction(requires_new: true) do
            Message.connection.execute(sql + m.message_id.to_s + ')')
          end
          cache[m.message_id] = true
        rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
        end
      end
    end

    BroadcastUserJob.perform_later({ type: 'thread:read', thread: @thread },
                                   current_user.user_id)

    set_cached_entry(:mark_read, current_user.user_id, cache)
  end

  def mark_message_read(thread, message)
    return if current_user.blank? || prefetch?
    cache = get_cached_entry(:mark_read, current_user.user_id) || {}

    are_read(thread.messages)

    unless cache[message.message_id]
      begin
        Message.transaction(requires_new: true) do
          Message.connection.execute('INSERT INTO read_messages (user_id, message_id) VALUES (' +
                                     current_user.user_id.to_s + ', ' + message.message_id.to_s + ')')
        end

        cache[message.message_id] = true
      rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
      end
    end

    BroadcastUserJob.perform_later({ type: 'message:read', thread: @thread, message: message },
                                   current_user.user_id)

    set_cached_entry(:mark_read, current_user.user_id, cache)
  end

  def forum_list_read(threads, activities)
    return if current_user.blank? || activities.values.blank?

    messages = []
    threads.each do |thread|
      messages += thread.messages.select { |m| m.deleted == false }
    end

    ids = messages.map(&:message_id)
    return if ids.blank?

    result = Message.connection.execute('SELECT message_id FROM read_messages WHERE message_id IN (' +
                                        ids.join(', ') + ') AND user_id = ' + current_user.user_id.to_s)

    result.each do |row|
      a = messages.find { |m| m.message_id == row['message_id'] }
      a.attribs['classes'] << 'visited'
    end
  end
end

# eof
