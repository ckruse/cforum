# -*- encoding: utf-8 -*-

class Score < ApplicationRecord
  self.primary_key = 'score_id'
  self.table_name  = 'scores'

  belongs_to :user
  belongs_to :vote
  belongs_to :message

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
