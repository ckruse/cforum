# -*- coding: utf-8 -*-

class NotifyNewMailer < ActionMailer::Base
  def new_message(user, thread, parent, message, url)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url

    mail(
      from: Rails.application.mail_sender,
      to: user.email,
      subject: I18n.t(
        'notifications.new_message',
        nick: message.author,
        subject: message.subject
      )
    )
  end

  def new_answer(user, thread, parent, message, url)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url

    mail(
      from: Rails.application.mail_sender,
      to: user.email,
      subject: I18n.t(
        'notifications.new_answer',
        nick: message.author,
        subject: message.subject
      )
    )
  end
end

# eof
