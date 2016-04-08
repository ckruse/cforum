# -*- encoding: utf-8 -*-

class Vote < ActiveRecord::Base
  UPVOTE   = 'upvote'
  DOWNVOTE = 'downvote'

  self.primary_key = 'vote_id'
  self.table_name  = 'votes'

  belongs_to :user
  belongs_to :message

  validates_presence_of :user_id, :message_id, :vtype
  validates_uniqueness_of :message_id, scope: :user_id
  validates :vtype, inclusion: [UPVOTE, DOWNVOTE]
end

# eof
