# -*- coding: utf-8 -*-

require 'strscan'

class Peon::Tasks::NotifyNewTask < Peon::Tasks::PeonTask
  def send_notify_message(user, thread, parent, message)
    Rails.logger.debug('notify new task: send mail to ' + user.email)

    begin
      if parent.owner && (parent.owner.user_id == user.user_id)
        NotifyNewMailer
          .new_answer(user, thread, parent, message,
                      message_url(thread, message), message.to_txt)
          .deliver_now

      else
        NotifyNewMailer
          .new_message(user, thread, parent, message,
                       message_url(thread, message), message.to_txt)
          .deliver_now
      end

      @sent_mails[user.email] = true

    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def perform_thread
    settings = Setting
                 .preload(:user)
                 .where("options->'notify_on_new_thread' = 'yes'")
                 .all

    settings.each do |setting|
      # ignore own messages
      next if setting.user_id == @message.user_id

      notify_user(setting.user, nil,
                  I18n.t('notifications.new_thread', nick: @message.author, subject: @message.subject),
                  message_path(@thread, @message), @message.message_id,
                  'message:create-answer', 'icon-new-activity')
    end
  end

  def perform_message
    messages = []
    parent = @message.parent_level

    until parent.blank?
      messages << parent.message_id
      parent = parent.parent_level
    end

    subscriptions = Subscription.preload(:user).where(message_id: messages).all
    subscriptions.each do |subscription|
      # don't notify if user is already notified
      next if @notified[subscription.user_id]
      # don't notify if user is creator of new message
      next if subscription.user_id == @message.user_id

      Rails.logger.debug 'notify new task: perform_message: subscriber: ' + subscription.user.inspect

      if uconf('notify_on_abonement_activity', subscription.user, @thread.forum) == 'email'
        send_notify_message(subscription.user, @thread, @parent, @message)
      end

      identifier = @parent.user_id == subscription.user_id ? 'notifications.new_answer' : 'notifications.new_message'
      notify_user(subscription.user, nil,
                  I18n.t(identifier, nick: @message.author, subject: @message.subject),
                  message_path(@thread, @message), @message.message_id,
                  'message:create-' + (@parent.user_id == subscription.user_id ? 'answer' : 'activity'),
                  'icon-new-activity')

      @notified[subscription.user_id] = true
    end
  end

  def send_mention_message(user)
    Rails.logger.debug('notify new task: send mention mail to ' + user.email)

    begin
      NotifyNewMailer.new_mention(user, @thread, @message, message_url(@thread, @message), @message.to_txt).deliver_now
      @sent_mails[user.email] = true

    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def may_read?(message, user)
    message.forum.read?(user) && (!message.deleted || message.forum.moderator?(user))
  end

  def notify_mention(user)
    Rails.logger.debug "found mention of user: #{user.inspect}"

    cfg = uconf('notify_on_mention', user, @thread.forum)

    return unless may_read?(@message, user)
    return if user.user_id == @message.user_id
    return if cfg == 'no'
    return if Notification.where(recipient_id: user.user_id,
                                 otype: 'message:mention',
                                 oid: @message.message_id).exists?
    return if @notified[user.user_id]

    send_mention_message(user) if (cfg == 'email') && !(@sent_mails[user.email])

    Rails.logger.debug "notify mention: #{user.inspect}"
    notify_user(user,
                nil,
                I18n.t('notifications.new_mention', nick: @message.author,
                                                    subject: @message.subject),
                message_path(@thread, @message),
                @message.message_id,
                'message:mention',
                'icon-new-activity')

    @notified[user.user_id] = true
  end

  def perform_mentions
    mentions = @message.md_mentions

    unless mentions.blank?
      mentions.each do |mention|
        next if mention.third # ignore mentions in cites

        user = User.find(mention.second)
        notify_mention(user)
      end
    end
  end

  def perform_no_messages_badge(user)
    no_messages = user.messages.where(deleted: false).count

    badges = [
      { messages: 100, name: 'chisel' },
      { messages: 1000, name: 'brush' },
      { messages: 2500, name: 'quill' },
      { messages: 5000, name: 'pen' },
      { messages: 7500, name: 'printing_press' },
      { messages: 10_000, name: 'typewriter' },
      { messages: 20_000, name: 'matrix_printer' },
      { messages: 30_000, name: 'inkjet_printer' },
      { messages: 40_000, name: 'laser_printer' },
      { messages: 50_000, name: '1000_monkeys' }
    ]

    badges.each do |badge|
      if no_messages >= badge[:messages]
        b = user.badges.find { |user_badge| user_badge.slug == badge[:name] }
        give_badge(user, Badge.where(slug: badge[:name]).first!) if b.blank?
      end
    end
  end

  def perform_badges(message)
    unless message.user_id.blank?
      perform_no_messages_badge(message.owner)

      if !message.parent_id.blank? && (message.parent.upvotes >= 1)
        votes = Vote.where(message_id: message.parent_id, user_id: message.user_id).first
        b = message.owner.badges.find { |user_badge| user_badge.slug == 'teacher' }

        if b.blank? && votes.blank? && (message.parent.user_id != message.user_id)
          give_badge(message.owner, Badge.where(slug: 'teacher').first!)
        end
      end
    end
  end

  def work_work(args)
    @notified = {}
    @sent_mails = {}

    # we don't care about exceptions, grunt will manage this for us
    @thread     = CfThread.includes(:forum, messages: :owner).find args['thread']

    sort_thread(@thread)

    @message    = @thread.find_message! args['message']
    @parent     = @thread.find_message @message.parent_id

    perform_mentions
    perform_badges(@message)

    case args['type']
    when 'thread'
      perform_thread
    when 'message'
      perform_message
    end
  end

  def sort_thread(thread, message = nil, direction = nil)
    direction = 'ascending' if direction.blank?

    if message.blank?
      thread.gen_tree(direction)
      return
    end

    unless message.messages.blank?
      if direction == 'ascending'
        message.messages.sort! { |a, b| a.created_at <=> b.created_at }
      else
        message.messages.sort! { |a, b| b.created_at <=> a.created_at }
      end

      for m in message.messages
        sort_thread(thread, m, direction)
      end
    end
  end
end

# eof
