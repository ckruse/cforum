module TitleHelper
  def set_title_infos
    return if current_user.blank?

    title = []

    if uconf('show_unread_notifications_in_title') == 'yes'
      notifications = @new_notifications || []
      title << notifications.length.to_s
    end

    if uconf('show_unread_pms_in_title') == 'yes'
      priv_msgs = @new_mails.length
      title << priv_msgs.to_s
    end

    if uconf('show_new_messages_since_last_visit_in_title') == 'yes'
      cnt = if current_user.last_sign_in_at.blank?
              0
            else
              Message
                .joins('LEFT JOIN read_messages ON messages.message_id = read_messages.message_id' \
                       ' AND read_messages.user_id = ' + current_user.user_id.to_s)
                .joins('INNER JOIN threads USING(thread_id)')
                .joins('LEFT JOIN invisible_threads ON invisible_threads.thread_id = threads.thread_id' \
                       ' AND invisible_threads.user_id = ' + current_user.user_id.to_s)
                .where('invisible_threads.thread_id IS NULL')
                .where('messages.forum_id IN (?)', @forums.map(&:forum_id))
                .where('read_messages.message_id IS NULL')
                .where('messages.deleted = false')
                .where('archived = false')
                .where('messages.created_at >= ?', current_user.last_sign_in_at)
                .count
            end

      title << cnt
    end

    @title_infos = '(' + title.join('/') + ') ' if title.present?
  end
end

# eof
