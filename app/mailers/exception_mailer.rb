class ExceptionMailer < ActionMailer::Base
  def new_exception(exception)
    @exception = exception

    mail(
      from: Rails.application.config.mail_sender,
      to: Rails.application.config.exception_mail_receiver,
      subject: 'Exception in Grunt'
    )
  end
end

# eof
