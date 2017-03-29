# -*- coding: utf-8 -*-

module VotesHelper
  def downvote_message(m, votes)
    may_downvote_msg = may_vote(m, Badge::DOWNVOTE)

    if !may_downvote_msg.blank?
      may_downvote_msg
    elsif has_downvote?(m, votes)
      t('messages.unvote')
    else
      t('messages.vote_down')
    end
  end

  def upvote_message(m, votes)
    may_upvote_msg = may_vote(m, Badge::UPVOTE)

    if !may_upvote_msg.blank?
      may_upvote_msg
    elsif has_upvote?(m, votes)
      t('messages.unvote')
    else
      t('messages.vote_up')
    end
  end

  def has_upvote?(m, votes)
    votes && votes[m.message_id] && votes[m.message_id].vtype == Vote::UPVOTE
  end

  def has_downvote?(m, votes)
    votes && votes[m.message_id] && votes[m.message_id].vtype == Vote::DOWNVOTE
  end
end

# eof