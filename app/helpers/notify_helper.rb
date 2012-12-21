# -*- coding: utf-8 -*-

module NotifyHelper
  def notify_user(user, hook, subject, template, vars, default = 'yes')
    return unless @config_manager.get(hook, default, user) == 'yes'

    str = render_to_string action: template, layout: false

    CfNotification.create(
      recipient_id: user.user_id,
      subject: subject,
      body: str
    )
  end
end

# eof
