# -*- coding: utf-8 -*-

module NotifyHelper
  def notify_user(user, hook, subject, path, icon = nil, default = 'yes')
    return unless @config_manager.get(hook, default, user) == 'yes'

    CfNotification.create(
      recipient_id: user.user_id,
      subject: subject,
      path: path,
      icon: icon
    )
  end

  def notifications
    @new_notifications = CfNotification.find_all_by_recipient_id_and_is_read(current_user.user_id, false) if current_user
  end

end

# eof
