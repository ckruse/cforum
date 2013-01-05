# -*- coding: utf-8 -*-

module NotifyHelper
  def notify_user(opts = {})
    opts = {icon: nil, default: 'yes', body: nil}.merge(opts)

    cfg = @config_manager.get(opts[:hook], opts[:default], opts[:user])
    return if cfg == 'no'

    CfNotification.create!(
      recipient_id: opts[:user].user_id,
      subject: opts[:subject],
      path: opts[:path],
      icon: opts[:icon],
      oid: opts[:oid],
      otype: opts[:otype]
    )

    NotificationMailer.new_notification(opts).deliver if cfg == 'email'
  end

  def notifications
    @new_notifications = CfNotification.find_all_by_recipient_id_and_is_read(current_user.user_id, false) if current_user
  end

end

# eof
