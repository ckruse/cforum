# -*- coding: utf-8 -*-

class NotifyNewMailer < ActionMailer::Base
  default from: "cforum@wwwtech.de"

  def new_message(user, thread, parent, message)
    @user = user
    @thread = thread
    @parent = parent
    @message = message

    mail(
      to: user.email,
      subject: I18n.t('mailers.subject_new_message', msg_subject: message.subject)
    )
  end
end

# eof
