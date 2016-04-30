# -*- coding: utf-8 -*-

class Cite < ActiveRecord::Base
  include ScoresHelper
  include ParserHelper

  self.primary_key = 'cite_id'
  self.table_name  = 'cites'

  belongs_to :message
  belongs_to :user
  belongs_to :creator_user, class_name: 'User'

  has_many :votes, class_name: 'CiteVote', foreign_key: :cite_id

  validates :author, length: { in: 2..60 }, allow_blank: true
  validates :cite, length: { in: 10..12288 }, presence: true
  validates_uniqueness_of :message_id, message: I18n.t('cites.already_exists'), if: :message_id

  def no_votes
    return votes.length
  end

  def score
    sum = 0

    votes.each do |v|
      sum += (v.vote_type == CiteVote::UPVOTE ? 1 : -1)
    end

    sum
  end

  def get_content
    self.cite
  end

  def id_prefix
    cite_id.to_s
  end
end

# eof