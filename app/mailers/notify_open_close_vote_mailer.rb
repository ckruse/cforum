class NotifyOpenCloseVoteMailer < ActionMailer::Base
  def notification_created_open(user, message)
    @user    = user
    @message = message

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'messages.close_vote.notification_created_open',
        subject: @message.subject,
        author: @message.author
      )
    )
  end

  def notification_created_close(user, message)
    @user    = user
    @message = message

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'messages.close_vote.notification_created_close',
        subject: @message.subject,
        author: @message.author
      )
    )
  end

  def notification_finished_open(user, message)
    @user    = user
    @message = message

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'messages.close_vote.notification_finished_open',
        subject: @message.subject,
        author: @message.author
      )
    )
  end

  def notification_finished_close(user, message)
    @user    = user
    @message = message

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t(
        'messages.close_vote.notification_finished_close',
        subject: @message.subject,
        author: @message.author
      )
    )
  end
end

# eof
