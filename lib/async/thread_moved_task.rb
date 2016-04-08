# -*- coding: utf-8 -*-


class Peon::Tasks::ThreadMovedTask < Peon::Tasks::PeonTask
  def send_notify_message(user, thread, old_forum, new_forum)
    Rails.logger.debug('notify new task: send mail to ' + user.email)

    begin
      ThreadMovedMailer.thread_moved(user, thread, old_forum, new_forum, message_url(thread, thread.messages.first)).deliver_now
    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def work_work(args)
    # we don't care about exceptions, grunt will manage this for us
    begin
      @thread     = CfThread.includes(:forum, messages: :owner).find args['thread']
      @old_forum  = Forum.find(args['old_forum'])
      @new_forum  = Forum.find(args['new_forum'])
    rescue ActiveRecord::RecordNotFound
      return
    end

    @notified = {}

    @thread.messages.each do |m|
      Rails.logger.debug "thread moved task: owner: " + m.owner.inspect
      next if m.owner.blank? or @notified[m.owner.user_id] or not @new_forum.read?(m.owner)

      @notified[m.owner.user_id] = true
      notify_me = uconf('notify_on_move', m.owner, @thread.forum)

      Rails.logger.debug 'user: ' + m.owner.username + ', setting: ' + notify_me.inspect

      if notify_me != 'no'
        Rails.logger.debug 'notify user ' + m.owner.username + ' about a moved thread'

        if notify_me == 'email'
          Rails.logger.debug 'notify user ' + m.owner.username + ' via mail'
          send_notify_message(m.owner, @thread, @old_forum, @new_forum)
        end

        notify_user(
          m.owner,
          nil,
          I18n.t('notifications.thread_moved',
                 subject: @thread.messages.first.subject,
                 old_forum: @old_forum.name,
                 new_forum: @new_forum.name),
          message_path(@thread, @thread.messages.first),
          @thread.thread_id,
          'thread:moved',
          'icon-new-activity'
        )
      end
    end

    int_messages = InterestingMessage.
                   preload(:user).
                   joins(:message).
                   where('thread_id = ?', @thread.thread_id).all
    int_messages.each do |it|
      Rails.logger.debug "thread moved task: owner: " + it.user.inspect
      next if @notified[it.user_id] or not @new_forum.read?(it.user)

      @notified[it.user_id] = true
      notify_me = uconf('notify_on_move', it.user, @thread.forum)

      Rails.logger.debug 'user: ' + it.user.username + ', setting: ' + notify_me.inspect

      if notify_me != 'no'
        Rails.logger.debug 'notify user ' + it.user.username + ' about a moved thread'

        if notify_me == 'email'
          Rails.logger.debug 'notify user ' + it.user.username + ' via mail'
          send_notify_message(it.user, @thread, @old_forum, @new_forum)
        end

        notify_user(
          it.user,
          nil,
          I18n.t('notifications.thread_moved',
                 subject: @thread.messages.first.subject,
                 old_forum: @old_forum.name,
                 new_forum: @new_forum.name),
          message_path(@thread, @thread.messages.first),
          @thread.thread_id,
          'thread:moved',
          'icon-new-activity'
        )
      end
    end
  end
end

# eof
