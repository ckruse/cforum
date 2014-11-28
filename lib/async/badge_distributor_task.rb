# -*- coding: utf-8 -*-

# peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
class Peon::Tasks::BadgeDistributor < Peon::Tasks::PeonTask
  def work_work(args)
    @message = nil

    @message = CfMessage.find(args['message_id']) if args['message_id']

    case args['type']
    when 'removed-vote', 'changed-vote'
    when 'voted'
      if not @message.user_id.blank?
        score = @message.owner.score
        badges = CfBadge.where('score_needed <= ?', score)
        user_badges = @message.owner.badges

        badges.each do |b|
          found = user_badges.find { |obj| obj.badge_id == b.badge_id }

          unless found
            @message.owner.badges_users.create(badge_id: b.badge_id, created_at: DateTime.now, updated_at: DateTime.now)
            notify_user(
              @message.owner, '', I18n.t('badges.badge_won',
                                         name: b.name,
                                         mtype: I18n.t("badges.badge_medal_types." + b.badge_medal_type)),
              cf_badge_path(b), b.badge_id, 'badge'
            )
          end
        end

      end
    end
  end
end

# eof
