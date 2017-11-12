class Vote < ApplicationRecord
  UPVOTE   = 'upvote'.freeze
  DOWNVOTE = 'downvote'.freeze

  self.primary_key = 'vote_id'
  self.table_name  = 'votes'

  belongs_to :user
  belongs_to :message
  has_one :score, dependent: :delete

  validates :user_id, :message_id, :vtype, presence: true
  validates :message_id, uniqueness: { scope: :user_id }
  validates :vtype, inclusion: [UPVOTE, DOWNVOTE]
end

# eof
