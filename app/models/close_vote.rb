# -*- coding: utf-8 -*-

class CloseVote < ApplicationRecord
  self.primary_key = 'close_vote_id'
  self.table_name  = 'close_votes'

  REASONS = %w(off-topic not-constructive illegal duplicate custom)

  has_many :voters, class_name: CloseVotesVoter,
           foreign_key: :close_vote_id, dependent: :delete_all
  belongs_to :message

  validates :reason, presence: true, inclusion: {in: REASONS}

  validates :duplicate_slug, presence: true,
            format: { with: /\A\/\d{4}\/\w{3}\/\d{1,2}\/[\w-]+\/\d+\z/ },
            if: Proc.new { |cv| cv.reason == "duplicate" }

  validates :custom_reason, presence: true,
            if: Proc.new { |cv| cv.reason == "custom" }


  def has_voted?(user)
    user = user.user_id if user.respond_to? :user_id

    voters.each do |v|
      if v.user_id == user
        return true
      end
    end

    return false
  end

  def audit_json
    as_json(include: {message: {include: {thread: {include: :forum}}}})
  end
end

# eof
