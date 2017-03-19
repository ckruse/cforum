# -*- encoding: utf-8 -*-

class Vote < ApplicationRecord
  UPVOTE   = 'upvote'.freeze
  DOWNVOTE = 'downvote'.freeze

  self.primary_key = 'vote_id'
  self.table_name  = 'votes'

  belongs_to :user
  belongs_to :message
  has_one :score

  validates_presence_of :user_id, :message_id, :vtype
  validates_uniqueness_of :message_id, scope: :user_id
  validates :vtype, inclusion: [UPVOTE, DOWNVOTE]
end

# eof
