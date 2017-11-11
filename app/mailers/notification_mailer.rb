class NotificationMailer < ActionMailer::Base
  def new_notification(opts)
    @opts = opts

    mail(
      from: Rails.application.config.mail_sender,
      to: opts[:user].email,
      subject: opts[:subject]
    )
  end
end

# eof
