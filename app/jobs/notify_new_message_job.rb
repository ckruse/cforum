class NotifyNewMessageJob < ApplicationJob
  queue_as :default

  def send_notify_message(user, thread, parent, message, sent_mails)
    Rails.logger.debug('notify new task: send mail to ' + user.email)

    begin
      if parent.owner && (parent.owner.user_id == user.user_id)
        NotifyNewMailer
          .new_answer(user, thread, parent, message,
                      message_url(thread, message), message.to_txt)
          .deliver_later

      else
        NotifyNewMailer
          .new_message(user, thread, parent, message,
                       message_url(thread, message), message.to_txt)
          .deliver_later
      end

      sent_mails[user.email] = true
    rescue => e # rubocop:disable Lint/RescueWithoutErrorClass
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def perform_thread(message, thread)
    settings = Setting
                 .preload(:user)
                 .where("options->>'notify_on_new_thread' = 'yes'")
                 .all

    settings.each do |setting|
      # ignore own messages
      next if setting.user_id == message.user_id

      notify_user(setting.user, nil,
                  I18n.t('notifications.new_thread', nick: message.author, subject: message.subject),
                  message_path(thread, message), message.message_id,
                  'message:create-answer', 'icon-new-activity')
    end
  end

  def perform_message(thread, message, parent_msg, notified, sent_mails)
    messages = []
    parent = message.parent_level

    until parent.blank?
      messages << parent.message_id
      parent = parent.parent_level
    end

    subscriptions = Subscription
                      .preload(:user)
                      .where(message_id: messages)
                      .all

    subscriptions.each do |subscription|
      # don't notify if user is already notified
      next if notified[subscription.user_id]
      # don't notify if user is creator of new message
      next if subscription.user_id == message.user_id

      Rails.logger.debug 'notify new task: perform_message: subscriber: ' + subscription.user.inspect

      if uconf('notify_on_abonement_activity', subscription.user, thread.forum) == 'email'
        send_notify_message(subscription.user, thread, parent_msg, message, sent_mails)
      end

      l10n_id, identifier = if parent_msg.user_id == subscription.user_id
                              ['notifications.new_answer', 'message:create-answer']
                            else
                              ['notifications.new_message', 'message:create-activity']
                            end

      notify_user(subscription.user, nil,
                  I18n.t(l10n_id, nick: message.author, subject: message.subject),
                  message_path(thread, message), message.message_id, identifier,
                  'icon-new-activity')

      notified[subscription.user_id] = true
    end
  end

  def send_mention_message(user, sent_mails)
    Rails.logger.debug('notify new task: send mention mail to ' + user.email)

    begin
      NotifyNewMailer.new_mention(user, @thread, @message,
                                  message_url(@thread, @message), @message.to_txt).deliver_later
      sent_mails[user.email] = true
    rescue => e # rubocop:disable Lint/RescueWithoutErrorClass
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def may_read?(message, user)
    message.forum.read?(user) && (!message.deleted || message.forum.moderator?(user))
  end

  def notify_user_about_mention(user, thread, message, notified, sent_mails)
    Rails.logger.debug "found mention of user: #{user.inspect}"

    cfg = uconf('notify_on_mention', user, thread.forum)

    return unless may_read?(message, user)
    return if user.user_id == message.user_id
    return if cfg == 'no'
    return if Notification.where(recipient_id: user.user_id,
                                 otype: 'message:mention',
                                 oid: message.message_id).exists?
    return if notified[user.user_id]

    send_mention_message(user, sent_mails) if (cfg == 'email') && !sent_mails[user.email]

    Rails.logger.debug "notify mention: #{user.inspect}"
    notify_user(user, nil,
                I18n.t('notifications.new_mention',
                       nick: message.author,
                       subject: message.subject),
                message_path(thread, message),
                message.message_id, 'message:mention',
                'icon-new-activity')

    notified[user.user_id] = true
  end

  def notify_mentions(thread, message, sent_mails, notified)
    mentions = message.md_mentions

    return if mentions.blank?

    mentions.each do |mention|
      next if mention.third # ignore mentions in cites

      user = User.find(mention.second)
      notify_user_about_mention(user, thread, message, notified, sent_mails)
    end
  end

  def perform(thread_id, message_id, type)
    notified = {}
    sent_mails = {}

    thread = CfThread
               .includes(:forum, messages: :owner)
               .where(thread_id: thread_id)
               .first

    return if thread.blank?

    sort_thread(thread)

    message = thread.find_message message_id
    parent = thread.find_message message.parent_id

    return if message.blank?

    notify_mentions(thread, message, sent_mails, notified)

    case type
    when 'thread'
      perform_thread(message, thread)
    when 'message'
      perform_message(thread, message, parent, notified, sent_mails)
    end
  end
end

# eof
