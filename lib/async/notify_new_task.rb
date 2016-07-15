# -*- coding: utf-8 -*-

require 'strscan'

class Peon::Tasks::NotifyNewTask < Peon::Tasks::PeonTask
  def check_notify(usr, thread, message, parent)
    return if usr.blank?

    Rails.logger.debug "notify new task: checking on #{usr.username}: notify_on_activity=" +
      uconf('notify_on_activity', usr, thread.forum) +
      ", notify_on_answer=" + uconf('notify_on_answer', usr, thread.forum)

    return if @sent_mails[usr.email] or @notified[usr.user_id] # do not send duplicate notifications
    return if usr.user_id == message.user_id # do not notify user about own messages
    return if is_invisible(usr, thread) # do not notify on invisible threads

    return true if uconf('notify_on_activity', usr, thread.forum) != 'no' # do not notify when not wanted

    return unless parent # do not notify if new thread
    return unless uconf('notify_on_answer', usr, thread.forum) != 'no' # do not notify if not wanted

    return true if parent.owner.try(:user_id) == usr.user_id # notify if parent is from looked-at user

    return
  end

  def send_notify_message(user, thread, parent, message)
    Rails.logger.debug('notify new task: send mail to ' + user.email)

    begin
      if parent.owner and parent.owner.user_id == user.user_id
        NotifyNewMailer.new_answer(user, thread, parent, message, message_url(thread, message), message.to_txt).deliver_now
      else
        NotifyNewMailer.new_message(user, thread, parent, message, message_url(thread, message), message.to_txt).deliver_now
      end

      @sent_mails[user.email] = true

    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end

  end

  def perform_thread
  end

  def perform_message
    @thread.messages.each do |m|
      Rails.logger.debug "notify new task: perform_message: owner: " + m.owner.inspect

      if check_notify(m.owner, @thread, @message, @parent)
        if uconf('notify_on_activity', m.owner, @thread.forum) == 'email' || uconf('notify_on_answer', m.owner, @thread.forum) == 'email'
          send_notify_message(m.owner, @thread, @parent, @message)
        end

        notify_user(
          m.owner,
          nil,
          @parent.user_id == m.user_id ?
                    I18n.t('notifications.new_answer', nick: @message.author,
                           subject: @message.subject) :
                    I18n.t('notifications.new_message', nick: @message.author,
                           subject: @message.subject),
          message_path(@thread, @message),
          @message.message_id,
                    'message:create-' + (@parent.user_id == m.user_id ?
                                         'answer' :
                                         'activity'),
          'icon-new-activity'
        )

        @notified[m.owner.user_id] = true
      end

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
    message.forum.read?(user) and (not message.deleted or message.forum.moderator?(user))
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

    if cfg == 'email' and not @sent_mails[user.email]
      send_mention_message(user)
    end

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
    mentions = @message.get_mentions

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
      { messages: 10000, name: 'typewriter' },
      { messages: 20000, name: 'matrix_printer' },
      { messages: 30000, name: 'inkjet_printer' },
      { messages: 40000, name: 'laser_printer' },
      { messages: 50000, name: '1000_monkeys' }
    ]

    badges.each do |badge|
      if no_messages >= badge[:messages]
        b = user.badges.find { |user_badge| user_badge.slug == badge[:name] }
        give_badge(user, Badge.where(slug: badge[:name]).first!) if b.blank?
      end
    end
  end

  def perform_badges(message)
    if not message.user_id.blank?
      perform_no_messages_badge(message.owner)

      if not message.parent_id.blank? and message.parent.upvotes >= 1
        votes = Vote.where(message_id: message.parent_id, user_id: message.user_id).first
        b = message.owner.badges.find { |user_badge| user_badge.slug == 'teacher' }

        if b.blank? and votes.blank? and message.parent.user_id != message.user_id
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
end

# eof
