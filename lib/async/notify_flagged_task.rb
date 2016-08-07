# -*- coding: utf-8 -*-

class Peon::Tasks::NotifyFlaggedTask < Peon::Tasks::PeonTask
  include LinksHelper

  def work_work(args)
    @message = nil
    @message = Message.preload(:forum, :thread).find(args['message_id']) if args['message_id']

    users = User.where("admin = true OR user_id IN (SELECT user_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE forum_id = ? AND permission = ?) OR user_id IN (SELECT user_id FROM badges_users INNER JOIN badges USING(badge_id) WHERE badge_type = ?)", @message.forum_id, ForumGroupPermission::ACCESS_MODERATE, Badge::MODERATOR_TOOLS)

    desc = I18n.t('messages.close_vote.' + @message.flags['flagged'])
    if @message.flags['flagged'] == 'custom'
      desc << "  \n" + @message.flags['custom_reason']
    end
    if @message.flags['flagged'] == 'duplicate'
      desc << "  \n[" + I18n.t('plugins.flag_plugin.duplicate_message') + "](" + @message.flags['flagged_dup_url'] + ")"
    end

    users.each do |u|
      if uconf('notify_on_flagged', u, @message.forum) != 'no'
        notify_user(u, nil,
                    I18n.t('plugins.flag_plugin.message_has_been_flagged',
                           subject: @message.subject,
                           author: @message.author),
                    message_path(@message.thread, @message, view_all: 'yes'),
                    @message.message_id,
                    'message:flagged',
                    nil,
                    desc
                   )

        if uconf('notify_on_flagged', u, @message.forum) == 'email'
          NotifyFlaggedMailer.new_flagged(u, @message,
                                          message_path(@message.thread, @message, view_all: "yes")).deliver_now
        end
      end
    end
  end
end

# eof
