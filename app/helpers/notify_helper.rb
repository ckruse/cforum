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

  def unnotify_user(oid, types = nil)
    CfNotification.delete_all(["oid = ? AND otype IN (?)", oid, types])
  end

  def check_for_deleting_notification(thread, message)
    had_one = false

    if user = current_user
      n = CfNotification.
        where(recipient_id: user.user_id,
              oid: message.message_id).
        where("otype IN ('message:create-answer','message:create-activity', 'message:mention')").
        first

      unless n.blank?
        had_one = true

        if (n.otype == 'message:create-answer' and
            uconf('delete_read_notifications_on_answer') == 'yes') or
          (n.otype == 'message:create-activity' and
           uconf('delete_read_notifications_on_activity') == 'yes') or
          (n.otype == 'message:mention' and
           uconf('delete_read_notifications_on_mention') == 'yes')
          n.destroy
        else
          n.is_read = true
          n.save!
        end
      end

      n = CfNotification.
          where(recipient_id: user.user_id,
                oid: thread.thread_id,
                is_read: false).
          where("otype IN ('thread:moved')").
          first

      unless n.blank?
        had_one = true
        n.is_read = true
        n.save!
      end
    end

    return had_one
  end
end

# eof
