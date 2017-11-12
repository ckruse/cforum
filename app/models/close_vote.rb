class CloseVote < ApplicationRecord
  self.primary_key = 'close_vote_id'
  self.table_name  = 'close_votes'

  REASONS = %w[off-topic not-constructive illegal duplicate custom spam].freeze

  has_many :voters, class_name: 'CloseVotesVoter',
                    foreign_key: :close_vote_id, dependent: :delete_all
  belongs_to :message

  validates :reason, presence: true, inclusion: { in: REASONS }

  validates :duplicate_slug, presence: true,
                             format: { with: %r{\A/\d{4}/\w{3}/\d{1,2}/[\w-]+/\d+\z} },
                             if: proc { |cv| cv.reason == 'duplicate' }

  validates :custom_reason, presence: true,
                            if: proc { |cv| cv.reason == 'custom' }

  def voted?(user)
    user = user.user_id if user.respond_to? :user_id

    voters.each do |v|
      return true if v.user_id == user
    end

    false
  end

  def audit_json
    as_json(include: { message: { include: { thread: { include: :forum } } } })
  end
end

# eof
