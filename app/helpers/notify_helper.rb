# -*- coding: utf-8 -*-

module NotifyHelper
  def notify_user(opts = {})
    opts = {icon: nil, default: 'yes', body: nil}.merge(opts)

    cfg = @config_manager.get(opts[:hook], opts[:default], opts[:user])
    return if cfg == 'no'

    n = CfNotification.create!(
      recipient_id: opts[:user].user_id,
      subject: opts[:subject],
      path: opts[:path],
      icon: opts[:icon],
      oid: opts[:oid],
      otype: opts[:otype]
    )

    publish("notification:create",
            {type: 'notification', notification: n},
            '/users/' + opts[:user].user_id.to_s)

    NotificationMailer.new_notification(opts).deliver_now if cfg == 'email'
  end

  def notifications
    if current_user
      @new_notifications = CfNotification.where(recipient_id: current_user.user_id, is_read: false)
      @new_mails = CfPrivMessage.where(owner: current_user.user_id, is_read: false)

      @undeceided_cites = CfCite.
                          where(archived: false).
                          where("NOT EXISTS (SELECT cite_id FROM cites_votes WHERE cite_id = cites.cite_id AND user_id = ?)",
                                current_user.user_id).count()
    end
  end

end

# eof
