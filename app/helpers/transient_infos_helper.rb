module TransientInfosHelper
  def transient_infos
    return if current_user.blank?

    @new_notifications = Notification.where(recipient_id: current_user.user_id, is_read: false)
    @new_mails = PrivMessage.where(owner: current_user.user_id, is_read: false)

    @undeceided_cites = Cite
                          .where(archived: false)
                          .where('NOT EXISTS (' \
                                 '  SELECT cite_id FROM cites_votes WHERE cite_id = cites.cite_id AND user_id = ?' \
                                 ')',
                                 current_user.user_id)
                          .count

    return unless current_user.moderator?

    @open_moderation_queue_entries_count = ModerationQueueEntry.where(cleared: false).count
  end
end

# eof
