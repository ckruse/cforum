# -*- coding: utf-8 -*-

class NotifyFlaggedJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.preload(:forum, :thread).find(message_id)
    users = admins_and_moderators(message.forum_id)

    desc = I18n.t('messages.close_vote.' + message.flags['flagged'])
    if message.flags['flagged'] == 'custom'
      desc << "  \n" + message.flags['custom_reason']
    end
    if message.flags['flagged'] == 'duplicate'
      desc << "  \n[" + I18n.t('plugins.flag_plugin.duplicate_message') + '](' + message.flags['flagged_dup_url'] + ')'
    end

    subject = I18n.t('plugins.flag_plugin.message_has_been_flagged', subject: message.subject, author: message.author)

    users.each do |u|
      next unless uconf('notify_on_flagged', u, message.forum) != 'no'
      notify_user(u, nil, subject,
                  message_path(message.thread, message, view_all: 'yes'),
                  message.message_id, 'message:flagged', nil, desc)

      if uconf('notify_on_flagged', u, message.forum) == 'email'
        NotifyFlaggedMailer.new_flagged(u, message,
                                        message_path(message.thread, message, view_all: 'yes')).deliver_later
      end
    end
  end
end

# eof
