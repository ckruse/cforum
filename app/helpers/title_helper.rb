# -*- coding: utf-8 -*-

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

    if uconf('show_new_messages_since_last_visit_in_title') == 'yes' and not current_user.last_sign_in_at.blank?
      cnt = Message.select('count(*) AS cnt').
            joins("LEFT JOIN read_messages ON read_messages.message_id = messages.message_id AND read_messages.user_id = " + current_user.user_id.to_s + " INNER JOIN threads USING(thread_id)").
            where('messages.forum_id IN (?) AND read_messages.message_id IS NULL AND messages.created_at > ? AND messages.deleted = false AND archived = false',
                  @forums.map { |f| f.forum_id }, current_user.last_sign_in_at).all

      title << cnt[0].cnt
    end

    @title_infos = '(' + title.join("/") + ') ' unless title.blank?
  end
end

# eof
