# -*- encoding: utf-8 -*-

class CfScore < ActiveRecord::Base
  self.primary_key = 'score_id'
  self.table_name  = 'scores'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :vote, class_name: 'CfVote'
  belongs_to :message, class_name: 'CfMessage'

  validates_numericality_of :value, only_integer: true
  validates_presence_of :user_id, :value
  # TODO: validate one of :vote_id, :message_id

  def get_message
    return if vote_id.blank? and message_id.blank?
    return message if vote_id.blank?
    vote.message
  end
end

# eof
