class NotifyModerationQueueJob < ApplicationJob
  queue_as :default

  def perform(mod_queue_entry_id)
    mod_queue_entry = ModerationQueueEntry.preload(message: %i[thread forum]).find(mod_queue_entry_id)
    users = admins_and_moderators(mod_queue_entry.message.forum_id)

    desc = I18n.t('messages.close_vote.' + mod_queue_entry.reason)
    if mod_queue_entry.reason == 'custom'
      desc << "  \n" + mod_queue_entry.custom_reason
    end
    if mod_queue_entry.reason == 'duplicate'
      desc << "  \n[" + I18n.t('plugins.flag_plugin.duplicate_message') + '](' + mod_queue_entry.duplicate_url + ')'
    end

    subject = I18n.t('plugins.flag_plugin.message_has_been_flagged',
                     subject: mod_queue_entry.message.subject,
                     author: mod_queue_entry.message.author)

    unread = ModerationQueueEntry.where(cleared: false).count

    users.each do |u|
      ActionCable
        .server
        .broadcast("users/#{u.user_id}",
                   type: 'moderation_queue_entry:create',
                   entry: mod_queue_entry, unread: unread)

      next unless uconf('notify_on_flagged', u, mod_queue_entry.message.forum) != 'no'
      notify_user(u, nil, subject, edit_moderation_queue_url(mod_queue_entry),
                  mod_queue_entry.moderation_queue_entry_id, 'moderation_queue_entry:created', nil, desc)

      next if uconf('notify_on_flagged', u, mod_queue_entry.message.forum) != 'email'

      NotifyFlaggedMailer
        .new_flagged(u, message,
                     edit_moderation_queue_url(mod_queue_entry))
        .deliver_later
    end
  end
end

# eof
