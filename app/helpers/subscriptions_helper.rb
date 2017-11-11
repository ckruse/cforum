module SubscriptionsHelper
  def subscribed?(message, user = current_user)
    return if user.blank?

    message = [message] if !message.is_a?(Array) && !message.is_a?(ActiveRecord::Relation)
    message = message.map { |m| m.is_a?(Message) ? m.message_id : m.to_i }

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:subscriptions, user_id) || {}

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

    subscribed_messages = []

    result = Message
               .connection
               .execute(format('SELECT message_id FROM subscriptions WHERE message_id IN (%s) AND user_id = %d',
                               message.join(', '), user_id))

    result.each do |row|
      m = row['thread_id'].to_i
      subscribed_messages << m
      new_cache[m] = true
    end

    merge_cached_entry(:subscriptions, usser_id, new_cache)

    subscribed_messages
  end

  def subscribe_message(message, user = current_user)
    return if user.blank?
    return if Subscription.where(user_id: user.user_id,
                                 message_id: message.message_id).exists?
    return if parent_subscribed?(message, user)

    Subscription.create!(user_id: user.user_id,
                         message_id: message.message_id)
  end

  def mark_threads_subscribed(threads, user = current_user)
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
      result = Message.connection.execute(format('SELECT message_id FROM subscriptions' \
                                                 '  WHERE message_id IN (%s) AND user_id = %d',
                                                 ids.join(', '), user.user_id))
      result.each do |row|
        new_cache[row['message_id'].to_i] = true
        mid = row['message_id'].to_i

        next unless messages_map[mid]

        messages_map[mid].first.attribs['classes'] << 'subscribed'
        messages_map[mid].first.attribs[:is_subscribed] = true
        messages_map[mid].second.attribs['classes'] << 'has-subscriptions'
        messages_map[mid].second.attribs[:has_subscriptions] = true
      end
    end

    merge_cached_entry(:interesting, user.user_id, new_cache)
  end

  def parent_subscribed?(message, user = current_user)
    return if user.blank?

    messages = []
    parent = message.parent_level

    until parent.blank?
      messages << parent.message_id
      parent = parent.parent_level
    end

    return if messages.blank?

    Subscription
      .where(user_id: user.user_id,
             message_id: messages)
      .exists?
  end

  def autosubscribe_message(thread, parent, message)
    confval = uconf('autosubscribe_on_post')
    return if confval == 'no'

    thread, message, = get_thread_w_post(thread.thread_id, message.message_id)
    parent = message if parent.blank?

    return if parent_subscribed?(message)

    case confval
    when 'yes'
      subscribe_message(parent)
    when 'own'
      subscribe_message(message)
    when 'root'
      subscribe_message(thread.message)
    end
  end
end

# eof
