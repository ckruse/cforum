# -*- coding: utf-8 -*-

class NotifyNewMailer < ActionMailer::Base
  def new_message(user, thread, parent, message, url, txt_content)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url
    @txt     = txt_content

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'notifications.new_message',
        nick: message.author,
        subject: message.subject
      )
    )
  end

  def new_answer(user, thread, parent, message, url, txt_content)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url
    @txt     = txt_content

    mail(
      from: Rails.application.config.mail_sender,
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
