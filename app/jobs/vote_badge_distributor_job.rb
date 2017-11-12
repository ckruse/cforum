class VoteBadgeDistributorJob < ApplicationJob
  queue_as :default

  def give_controverse(user)
    b = user.badges.find { |user_badge| user_badge.slug == 'controverse' }
    give_badge(user, Badge.where(slug: 'controverse').first!) if b.blank?
  end

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

    return unless (user_should_have_badges - all_user_badges).positive?

    (user_should_have_badges - all_user_badges).times do
      give_badge(vote.user, voter_badge)
    end
  end

  def perform(vote_id, message_id, type)
    message = nil
    vote = nil

    logger.debug "starting VoteBadgeDistributorJob with arguments #{vote_id.inspect}," \
                 " #{message_id.inspect}, #{type.inspect}"

    if message_id
      message = Message.where(message_id: message_id).first
      return if message.blank?
    end

    if vote_id
      vote = Vote.where(vote_id: vote_id).first
      logger.debug "vote is: #{vote.inspect}"
      return if vote.blank?
    end

    check_for_voter_badges(vote) if %w[changed-vote voted].include?(type)
    logger.debug 'starting message owner badges'

    case type
    # when 'removed-vote', 'changed-vote', 'unaccepted'
    when 'voted', 'accepted'
      return if message.user_id.blank?

      logger.debug "type: #{type} - pre check_for_owner_vote_badges"
      if type == 'voted'
        check_for_owner_vote_badges(message.owner, message)
        give_controverse(message.owner) if (message.upvotes >= 5) && (message.downvotes >= 5)
      end

      score = message.owner.score
      badges = Badge.where('score_needed <= ?', score)
      user_badges = message.owner.badges

      logger.debug "score: #{score}"

      badges.each do |b|
        logger.debug "Checking for badge #{b.name} to user #{message.owner.username}"
        found = user_badges.find { |obj| obj.badge_id == b.badge_id }

        next if found
        logger.debug 'giving badge!'
        message.owner.badge_users.create(badge_id: b.badge_id, created_at: Time.zone.now, updated_at: Time.zone.now)
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
