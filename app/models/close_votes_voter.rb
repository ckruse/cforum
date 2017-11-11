class CloseVotesVoter < ApplicationRecord
  self.primary_key = 'close_votes_voter_id'
  self.table_name  = 'close_votes_voters'

  belongs_to :close_votes, class_name: 'CloseVote'

  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :close_vote_id }
end

# eof
