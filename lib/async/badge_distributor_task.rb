# -*- coding: utf-8 -*-

# peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
module Peon
  module Tasks
    class BadgeDistributor < Peon::Tasks::PeonTask
      def initialize(periodical = false)
        super()
        @periodical = periodical
      end

      def check_for_yearling_badges(user)
        yearling = CfBadge.where(slug: 'yearling').first!
        last_yearling = user.badges_users.where(badge_id: yearling.badge_id).order(created_at: :desc).first

        difference = if last_yearling.blank?
                       DateTime.now - user.created_at.to_datetime
                     else
                       DateTime.now - last_yearling.created_at.to_datetime
                     end

        years = (difference / 365).floor
        years = 0 if years < 0
        years.times do
          give_badge(user, yearling)
        end
      end

      def check_for_owner_vote_badges(user, message)
        badges = [
          {votes: 1, name: 'donee'},
          {votes: 5, name: 'nice_answer'},
          {votes: 10, name: 'good_answer'},
          {votes: 15, name: 'great_answer'},
          {votes: 20, name: 'superb_answer'}
        ]

        votes = message.score

        badges.each do |badge|
          if votes >= badge[:votes]
            b = user.badges.find { |user_badge| user_badge.slug == badge[:name] }
            give_badge(user, CfBadge.where(slug: badge[:name]).first!) if b.blank?
          end
        end

        if message.upvotes >= 5 and message.downvotes >= 5
          b = user.badges.find { |user_badge| user_badge.slug == 'controverse' }
          give_badge(user, CfBadge.where(slug: 'controverse').first!) if b.blank?
        end
      end

      def check_for_voter_badges(vote)
        no_upvotes = CfVote.where(user_id: vote.user_id, vtype: CfVote::UPVOTE).count()
        no_downvotes = CfVote.where(user_id: vote.user_id, vtype: CfVote::DOWNVOTE).count()

        if no_upvotes >= 0
          b = vote.user.badges.find { |ubadge| ubadge.slug == 'enthusiast' }
          give_badge(vote.user, CfBadge.where(slug: 'enthusiast').first!) if b.blank?
        end

        if no_downvotes >= 0
          b = vote.user.badges.find { |ubadge| ubadge.slug == 'critic' }
          give_badge(vote.user, CfBadge.where(slug: 'critic').first!) if b.blank?
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
        @vote = nil

        @message = CfMessage.find(args['message_id']) if args['message_id']
        @vote = CfVote.find(args['vote_id']) if args['vote_id']

        case args['type']
        when 'removed-vote', 'changed-vote', 'unaccepted'
        when 'voted', 'accepted'
          check_for_voter_badges(@vote)

          if not @message.user_id.blank?
            check_for_owner_vote_badges(@message.owner, @message) if args['type'] == 'voted'

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
