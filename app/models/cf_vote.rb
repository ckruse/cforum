# -*- encoding: utf-8 -*-

class CfVote < ActiveRecord::Base
  UPVOTE   = 'upvote'
  DOWNVOTE = 'downvote'

  self.primary_key = 'vote_id'
  self.table_name  = 'votes'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :message, class_name: 'CfMessage'

  attr_accessible :voting_id, :user_id, :message_id, :vtype
end

# eof
