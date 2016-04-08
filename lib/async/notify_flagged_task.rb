# -*- coding: utf-8 -*-

class Peon::Tasks::NotifyFlaggedTask < Peon::Tasks::PeonTask
  def work_work(args)
    @message = nil
    @message = Message.preload(:forum, :thread).find(args['message_id']) if args['message_id']

    users = User.where("admin = true OR user_id IN (SELECT user_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE forum_id = ? AND permission = ?) OR user_id IN (SELECT user_id FROM badges_users INNER JOIN badges USING(badge_id) WHERE badge_type = ?)", @message.forum_id, ForumGroupPermission::ACCESS_MODERATE, RightsHelper::MODERATOR_TOOLS)

    users.each do |u|
      if uconf('notify_on_flagged', u, @message.forum) != 'no'
        notify_user(u, nil,
                    I18n.t('plugins.flag_plugin.message_has_been_flagged',
                           subject: @message.subject,
                           author: @message.author),
                    message_path(@message.thread, @message),
                    @message.message_id,
                    'message:flagged',
                    nil
                   )

        if uconf('notify_on_flagged', u, @message.forum) == 'email'
          NotifyFlaggedMailer.new_flagged(u, @message).deliver_now
        end
      end
    end
  end
end

# eof
