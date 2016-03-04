# -*- coding: utf-8 -*-

# peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
module Peon
  module Tasks
    class BadgeDistributor < Peon::Tasks::PeonTask
      def initialize(periodical = false)
        super()
        @periodical = periodical
      end

      def give_badge(user, badge)
        CfBadge.transaction do
          user.badges_users.create!(badge_id: badge.badge_id,
                                    created_at: Time.zone.now,
                                    updated_at: Time.zone.now)

          audit(user, 'badge-gained', nil)
          notify_user(user, '', I18n.t('badges.badge_won',
                                       name: badge.name,
                                       mtype: I18n.t("badges.badge_medal_types." + badge.badge_medal_type)),
                      cf_badge_path(badge), badge.badge_id, 'badge')
        end
      end

      def check_for_yearling_badges(user)
        yearling = CfBadge.where(slug: 'yearling').first!
        last_yearling = user.badges_users.where(badge_id: yearling.badge_id).order(created_at: :desc).first

        years = 0
        if last_yearling.blank?
          time_registered = DateTime.now - user.created_at.to_datetime
          years = (time_registered / 365).floor
        else
          time_between = DateTime.now - last_yearling.created_at.to_datetime
          years = (time_between / 365).floor
        end

        years = 0 if years < 0
        years.times do
          give_badge(user, yearling)
        end
      end

      def run_periodical(args)
        CfUser.order(:user_id).all.each do |u|
          check_for_yearling_badges(u)
          return
        end
      end

      def work_work(args)
        if @periodical
          run_periodical(args)
          return
        end

        @message = nil

        @message = CfMessage.find(args['message_id']) if args['message_id']

        case args['type']
        when 'removed-vote', 'changed-vote', 'unaccepted'
        when 'voted', 'accepted'
          if not @message.user_id.blank?
            score = @message.owner.score
            badges = CfBadge.where('score_needed <= ?', score)
            user_badges = @message.owner.badges

            badges.each do |b|
              found = user_badges.find { |obj| obj.badge_id == b.badge_id }

              unless found
                @message.owner.badges_users.create(badge_id: b.badge_id, created_at: DateTime.now, updated_at: DateTime.now)
                @message.owner.reload
                audit(@message.owner, 'badge-gained', nil)
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

    # every two hours
    Peon::Grunt.instance.periodical(BadgeDistributor.new(true), 7200)
  end
end

# eof
