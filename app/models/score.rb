class Score < ApplicationRecord
  self.primary_key = 'score_id'
  self.table_name  = 'scores'

  belongs_to :user
  belongs_to :vote
  belongs_to :message

  validates :value, numericality: { only_integer: true }
  validates :user_id, :value, presence: true
  # TODO: validate one of :vote_id, :message_id

  def get_message # rubocop:disable Naming/AccessorMethodName
    return if vote_id.blank? && message_id.blank?
    return message if vote_id.blank?
    vote.message
  end
end

# eof
