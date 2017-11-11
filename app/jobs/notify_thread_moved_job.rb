class NotifyThreadMovedJob < ApplicationJob
  queue_as :default

  def notify_user_about_move(user, thread, old_forum, new_forum, notified, subject)
    notified[user.user_id] = true
    notify_me = uconf('notify_on_move', user, thread.forum)

    Rails.logger.debug 'user: ' + user.username + ', setting: ' + notify_me.inspect

    return if notify_me == 'no'
    Rails.logger.debug 'notify user ' + user.username + ' about a moved thread'

    if notify_me == 'email'
      Rails.logger.debug 'notify user ' + user.username + ' via mail'
      send_notify_message(user, thread, old_forum, new_forum)
    end

    notify_user(user, nil, subject, message_path(thread, thread.messages.first),
                thread.thread_id, 'thread:moved', 'icon-new-activity')
  end

  def perform(thread_id, old_forum_id, new_forum_id)
    # we don't care about exceptions, grunt will manage this for us
    thread     = CfThread.includes(:forum, messages: :owner).find thread_id
    old_forum  = Forum.find(old_forum_id)
    new_forum  = Forum.find(new_forum_id)

    notified = {}

    subject = I18n.t('notifications.thread_moved',
                     subject: thread.messages.first.subject,
                     old_forum: old_forum.name,
                     new_forum: new_forum.name)

    thread.messages.each do |m|
      Rails.logger.debug 'thread moved task: owner: ' + m.owner.inspect
      next if m.owner.blank? || notified[m.owner.user_id] || !new_forum.read?(m.owner)
      notify_user_about_move(m.owner, thread, old_forum, new_forum, notified, subject)
    end

    int_messages = InterestingMessage
                     .preload(:user)
                     .joins(:message)
                     .where('thread_id = ?', thread.thread_id)
                     .all

    int_messages.each do |it|
      Rails.logger.debug 'thread moved task: owner: ' + it.user.inspect
      next if notified[it.user_id] || !new_forum.read?(it.user)
      notify_user_about_move(it.user, thread, old_forum, new_forum, notified, subject)
    end

    subscriptions = Subscription
                      .preload(:user)
                      .joins(:message)
                      .where('thread_id = ?', thread.thread_id)
                      .all

    subscriptions.each do |subscription|
      Rails.logger.debug 'thread moved task: owner: ' + subscription.user.inspect
      next if notified[subscription.user_id] || !new_forum.read?(subscription.user)
      notify_user_about_move(subscription.user, thread, old_forum, new_forum, notified, subject)
    end
  end

  def send_notify_message(user, thread, old_forum, new_forum)
    Rails.logger.debug('notify new task: send mail to ' + user.email)

    ThreadMovedMailer
      .thread_moved(user, thread, old_forum, new_forum,
                    message_url(thread, thread.messages.first))
      .deliver_later
  end
end

# eof
