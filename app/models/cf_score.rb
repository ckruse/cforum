# -*- encoding: utf-8 -*-

class CfScore < ActiveRecord::Base
  self.primary_key = 'score_id'
  self.table_name  = 'scores'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :vote, class_name: 'CfVote'

  attr_accessible :score_id, :user_id, :vote_id, :value

  validates_numericality_of :value, only_integer: true
  validates_presence_of :user_id, :vote_id, :value
end

# eof
