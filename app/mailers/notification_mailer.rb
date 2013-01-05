# -*- coding: utf-8 -*-

class NotificationMailer < ActionMailer::Base
  default from: "cforum@wwwtech.de"

  def new_notification(opts)
    @opts = opts

    mail(
      to: opts[:user].email,
      subject: opts[:subject]
    )
  end
end

# eof
