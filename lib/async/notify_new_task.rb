# -*- coding: utf-8 -*-


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

    return true if parent.owner.user_id == usr.user_id # notify if parent is from looked-at user

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

  def perform_thread(args)
  end

  def perform_message(args)
    # we don't care about exceptions, grunt will manage this for us
    begin
      @thread     = CfThread.includes(:forum, :messages => :owner).find args['thread']
      @message    = @thread.find_message! args['message']
      @parent     = @thread.find_message @message.parent_id
    rescue ActiveRecord::RecordNotFound, CForum::NotFoundException
      return
    end

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

  def work_work(args)
    case args['type']
    when 'thread'
      perform_thread(args)
    when 'message'
      perform_message(args)
    end
  end
end

# eof
