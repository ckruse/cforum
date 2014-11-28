# -*- coding: utf-8 -*-

# peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
class Peon::Tasks::BadgeDistributor < Peon::Tasks::PeonTask
  def work_work(args)
    @message = nil

    @message = CfMessage.find(args['message_id']) if args['message_id']

    case args['type']
    when 'removed-vote', 'changed-vote'
    when 'voted'
      if @message.author_id
        score = @message.author.score
        badges = CfBadge.where('score_needed <= ?', score)
        user_badges = @message.author.badges

        badges.each do |b|
          found = user_badges.find { |obj| obj.badge_id == b.badge_id }

          unless found
            @message.author.badges.create(badge_id: b.badge_id)
            notify_user(
              @message.author, '', t('admin.badges.badge_won', name: b.name),
              badge_path(b), nil, nil
            )
          end
        end

      end
    end
  end
end

# eof
