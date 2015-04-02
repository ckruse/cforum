# -*- coding: utf-8 -*-

class Peon::Tasks::NotifyOpenCloseVoteTask < Peon::Tasks::PeonTask
  def work_work(args)
    @message = nil
    @message = CfMessage.preload(:forum, :thread).find(args['message_id']) if args['message_id']

    if @message
      users = CfUser.where("admin = true OR user_id IN (SELECT user_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE forum_id = ? AND permission = ?) OR user_id IN (SELECT user_id FROM badges_users INNER JOIN badges USING(badge_id) WHERE badge_type = ?)",
                           @message.forum_id,
                           CfForumGroupPermission::ACCESS_MODERATE,
                           RightsHelper::MODERATOR_TOOLS)

      users.each do |u|
        if uconf('notify_on_open_close_vote', u, @message.forum) != 'no'
          trans_key = 'messages.close_vote.notification'
          noti_type = 'message:open_close_vote'

          if args['type'] == 'created'
            trans_key << '_created'
            noti_type << '_created'
          else
            trans_key << '_finished'
            noti_type << '_finished'
          end

          if args['vote_type']
            trans_key << '_open'
            noti_type << '_open'
          else
            trans_key << '_close'
            noti_type << '_close'
          end

          notify_user(u, nil,
                      I18n.t(trans_key,
                             subject: @message.subject,
                             author: @message.author),
                      cf_message_path(@message.thread, @message),
                      @message.message_id, noti_type, nil)

          if uconf('notify_on_open_close_vote', u, @message.forum) == 'email'
            m = trans_key.gsub(/messages\.close_vote\./, '')
            NotifyOpenCloseVoteMailer.send(m, u, @message).deliver
          end
        end
      end
    end
  end
end

# eof
