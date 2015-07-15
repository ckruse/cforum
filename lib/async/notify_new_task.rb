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
        NotifyNewMailer.new_answer(user, thread, parent, message, cf_message_url(thread, message), message.to_txt).deliver
      else
        NotifyNewMailer.new_message(user, thread, parent, message, cf_message_url(thread, message), message.to_txt).deliver
      end

      @sent_mails[user.email] = true

    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end

  end

  def perform_thread
  end

  def perform_message
    @sent_mails = {}
    @notified   = {}

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
          cf_message_path(@thread, @message),
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
      NotifyNewMailer.new_mention(user, @thread, @message, cf_message_url(@thread, @message), @message.to_txt).deliver
      @sent_mails[user.email] = true

    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def notify_mention(user)
    Rails.logger.debug "found mention of user: #{user.inspect}"

    cfg = uconf('notify_on_mention', user, @thread.forum)

    return if user.user_id == @message.user_id
    return if cfg == 'no'
    return if CfNotification.where(recipient_id: user.user_id, otype: 'message:mention').exists?
    return if @notified[user.user_id]

    if cfg == 'email' and not @sent_mails[user.email]
      send_mention_message(user)
    end

    Rails.logger.debug "notify mention: #{user.inspect}"
    notify_user(user,
                nil,
                I18n.t('notifications.new_mention', nick: @message.author,
                       subject: @message.subject),
                cf_message_path(@thread, @message),
                @message.message_id,
                'message:mention',
                'icon-new-activity')

    @notified[user.user_id] = true
  end

  def perform_mentions
    @notified = {}
    @sent_mails = {}

    Rails.logger.debug "looking for mentions...."
    doc = StringScanner.new(@message.content)

    while doc.scan_until(/@[^@\n]+/)
      nick = doc.matched[1..-1].strip[0..60]
      Rails.logger.debug "Looking for: #{nick}"

      while nick.length > 2 and (user = CfUser.where(username: nick).first).blank?
        nick = nick.gsub(/\s*\w+$/, '')
        Rails.logger.debug "(in loop) looking for: #{nick}"
      end

      notify_mention(user) if not user.blank?
    end

    Rails.logger.debug "mentions finished!"
  end

  def work_work(args)
    # we don't care about exceptions, grunt will manage this for us
    @thread     = CfThread.includes(:forum, messages: :owner).find args['thread']
    @message    = @thread.find_message! args['message']
    @parent     = @thread.find_message @message.parent_id

    case args['type']
    when 'thread'
      perform_thread
    when 'message'
      perform_message
    end

    perform_mentions
  end
end

# eof
