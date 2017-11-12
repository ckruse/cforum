module VotesHelper
  def downvote_message(m, votes)
    may_downvote_msg = may_vote?(m, Badge::DOWNVOTE)

    if may_downvote_msg.present?
      may_downvote_msg
    elsif downvoted?(m, votes)
      t('messages.unvote')
    else
      t('messages.vote_down')
    end
  end

  def upvote_message(m, votes)
    may_upvote_msg = may_vote?(m, Badge::UPVOTE)

    if may_upvote_msg.present?
      may_upvote_msg
    elsif upvoted?(m, votes)
      t('messages.unvote')
    else
      t('messages.vote_up')
    end
  end

  def upvoted?(m, votes)
    votes && votes[m.message_id] && votes[m.message_id].vtype == Vote::UPVOTE
  end

  def downvoted?(m, votes)
    votes && votes[m.message_id] && votes[m.message_id].vtype == Vote::DOWNVOTE
  end
end

# eof
