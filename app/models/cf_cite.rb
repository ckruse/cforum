# -*- coding: utf-8 -*-

class CfCite < ActiveRecord::Base
  include ScoresHelper

  self.primary_key = 'cite_id'
  self.table_name  = 'cites'

  belongs_to :message, class_name: 'CfMessage'
  belongs_to :user, class_name: 'CfUser'
  belongs_to :creator_user, class_name: 'CfUser'

  has_many :votes, class_name: 'CfCiteVote', foreign_key: :cite_id

  validates :author, length: { in: 2..60 }, allow_blank: true
  validates :cite, length: { in: 10..12288 }, presence: true

  def no_votes
    return votes.length
  end

  def score
    sum = 0

    votes.each do |v|
      sum += (v.vote_type == CfCiteVote::UPVOTE ? 1 : -1)
    end

    sum
  end
end

# eof
