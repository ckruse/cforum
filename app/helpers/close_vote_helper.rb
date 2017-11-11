module CloseVoteHelper
  def vote_action(vote)
    conf('close_vote_action_' + vote.reason)
  end
end

# eof
