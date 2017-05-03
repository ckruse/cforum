# -*- coding: utf-8 -*-

class VoteBadgeDistributorJob < ApplicationJob
  queue_as :default

  def check_for_owner_vote_badges(user, message)
    badges = [
      { votes: 1, name: 'donee' },
      { votes: 5, name: 'nice_answer' },
      { votes: 10, name: 'good_answer' },
      { votes: 15, name: 'great_answer' },
      { votes: 20, name: 'superb_answer' }
    ]

    votes = message.score

    badges.each do |badge|
      if votes >= badge[:votes]
        b = user.badges.find { |user_badge| user_badge.slug == badge[:name] }
        give_badge(user, Badge.where(slug: badge[:name]).first!) if b.blank?
      end
    end

    if (message.upvotes >= 5) && (message.downvotes >= 5)
      b = user.badges.find { |user_badge| user_badge.slug == 'controverse' }
      give_badge(user, Badge.where(slug: 'controverse').first!) if b.blank?
    end
  end

  def check_for_voter_badges(vote)
    if vote.vtype == Vote::UPVOTE
      b = vote.user.badges.find { |ubadge| ubadge.slug == 'enthusiast' }
      give_badge(vote.user, Badge.where(slug: 'enthusiast').first!) if b.blank?
    end

    if vote.vtype == Vote::DOWNVOTE
      b = vote.user.badges.find { |ubadge| ubadge.slug == 'critic' }
      give_badge(vote.user, Badge.where(slug: 'critic').first!) if b.blank?
    end

    badges = [100, 250, 500, 1000, 2500, 5000, 10_000]
    voter_badge = Badge.where(slug: 'voter').first!
    all_user_votes = Vote.where(user_id: vote.user_id).count
    all_user_badges = BadgeUser.where(user_id: vote.user_id, badge_id: voter_badge.badge_id).count
    user_should_have_badges = 0

    badges.each do |vote_no|
      user_should_have_badges += 1 if all_user_votes >= vote_no
    end

    if user_should_have_badges - all_user_badges > 0
      (user_should_have_badges - all_user_badges).times do
        give_badge(vote.user, voter_badge)
      end
    end
  end

  def perform(vote_id, message_id, type)
    message = nil
    vote = nil

    message = Message.find(message_id) if message_id
    vote = Vote.find(vote_id) if vote_id

    check_for_voter_badges(vote) if %w(changed-vote voted).include?(type)

    case type
    when 'removed-vote', 'changed-vote', 'unaccepted'
    when 'voted', 'accepted'
      return if message.user_id.blank?

      check_for_owner_vote_badges(message.owner, message) if type == 'voted'

      score = message.owner.score
      badges = Badge.where('score_needed <= ?', score)
      user_badges = message.owner.badges

      badges.each do |b|
        found = user_badges.find { |obj| obj.badge_id == b.badge_id }

        next if found
        message.owner.badge_users.create(badge_id: b.badge_id, created_at: DateTime.now, updated_at: DateTime.now)
        message.owner.reload
        audit(message.owner, 'badge-gained', nil)
        notify_user(message.owner, '', I18n.t('badges.badge_won',
                                              name: b.name,
                                              mtype: I18n.t('badges.badge_medal_types.' + b.badge_medal_type)),
                    badge_path(b), b.badge_id, 'badge')

      end
    end
  end
end

# eof