# -*- encoding: utf-8 -*-

class CfVote < ActiveRecord::Base
  UPVOTE   = 'upvote'
  DOWNVOTE = 'downvote'

  self.primary_key = 'vote_id'
  self.table_name  = 'votes'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :message, class_name: 'CfMessage'

  validates_presence_of :user_id, :message_id, :vtype
  validates_uniqueness_of :message_id, :scope => :user_id
  validates :vtype, inclusion: [UPVOTE, DOWNVOTE]
end

# eof
