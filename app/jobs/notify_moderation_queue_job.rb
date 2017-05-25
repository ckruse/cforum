# -*- coding: utf-8 -*-

class NotifyModerationQueueJob < ApplicationJob
  queue_as :default

  def perform(mod_queue_entry_id)
    mod_queue_entry = ModerationQueueEntry.preload(message: [:thread, :forum]).find(mod_queue_entry_id)
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

    users.each do |u|
      next unless uconf('notify_on_flagged', u, mod_queue_entry.message.forum) != 'no'
      notify_user(u, nil, subject, edit_moderation_queue_url(mod_queue_entry),
                  mod_queue_entry.moderation_queue_entry_id, 'message:flagged', nil, desc)

      next if uconf('notify_on_flagged', u, mod_queue_entry.message.forum) != 'email'

      NotifyFlaggedMailer
        .new_flagged(u, message,
                     edit_moderation_queue_url(mod_queue_entry))
        .deliver_later
    end
  end
end

# eof
