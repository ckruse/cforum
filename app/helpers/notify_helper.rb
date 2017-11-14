module NotifyHelper
  def notify_user(opts = {})
    opts = { icon: nil, default: 'yes', body: nil }.merge(opts)

    if opts[:hook].present?
      cfg = @config_manager.get(opts[:hook], opts[:user])
      return if cfg == 'no'
    end

    n = Notification.create!(
      recipient_id: opts[:user].user_id,
      subject: opts[:subject],
      path: opts[:path],
      icon: opts[:icon],
      oid: opts[:oid],
      otype: opts[:otype]
    )

    unread = Notification.where(recipient_id: opts[:user].user_id, is_read: false).count
    BroadcastUserJob.perform_later({ type: 'notification:create', notification: n, unread: unread },
                                   opts[:user].user_id)
    NotificationMailer.new_notification(opts).deliver_later if cfg == 'email'
  end

  def unnotify_user(oid, types = nil)
    Notification.where('oid = ? AND otype IN (?)', oid, types).delete_all
  end

  def check_for_deleting_notification(thread, message)
    had_one = false

    if current_user.present?
      n = Notification
            .where(recipient_id: current_user.user_id,
                   oid: message.message_id)
            .where("otype IN ('message:create-answer','message:create-activity', 'message:mention')")
            .first

      if n.present?
        had_one = true

        if (n.otype.in?(['message:create-answer', 'message:create-activity']) &&
            uconf('delete_read_notifications_on_abonements') == 'yes') ||
           (n.otype == 'message:mention' &&
            uconf('delete_read_notifications_on_mention') == 'yes')
          n.destroy
        else
          n.is_read = true
          n.save!
        end
      end

      n = Notification
            .where(recipient_id: current_user.user_id,
                   oid: thread.thread_id,
                   is_read: false)
            .where("otype IN ('thread:moved')")
            .first

      if n.present?
        had_one = true
        n.is_read = true
        n.save!
      end
    end

    if had_one
      BroadcastUserJob.perform_later({ type: 'notification:update',
                                       unread: unread_notifications },
                                     current_user.user_id)
    end

    had_one
  end

  def unread_notifications(user = current_user)
    Notification.where(recipient_id: user.user_id, is_read: false).count
  end
end

# eof
