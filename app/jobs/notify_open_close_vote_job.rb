class NotifyOpenCloseVoteJob < ApplicationJob
  queue_as :default

  def perform(message_id, type, vote_type)
    message = Message.preload(:forum, :thread).find(message_id)
    users = admins_and_moderators(message.forum_id)

    trans_key = 'messages.close_vote.notification'
    noti_type = 'message:open_close_vote'

    if type == 'created'
      trans_key << '_created'
      noti_type << '_created'
    else
      trans_key << '_finished'
      noti_type << '_finished'
    end

    if vote_type == 'open'
      trans_key << '_open'
      noti_type << '_open'
    else
      trans_key << '_close'
      noti_type << '_close'
    end

    subject = I18n.t(trans_key, subject: message.subject, author: message.author)

    users.each do |u|
      next if uconf('notify_on_open_close_vote', u, message.forum) == 'no'

      notify_user(u, nil, subject,
                  message_path(message.thread, message),
                  message.message_id, noti_type, nil)

      if uconf('notify_on_open_close_vote', u, message.forum) == 'email'
        m = trans_key.gsub(/messages\.close_vote\./, '')
        NotifyOpenCloseVoteMailer.send(m, u, message).deliver_later
      end
    end
  end
end

# eof
