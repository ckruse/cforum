class Subscription < ApplicationRecord
  self.primary_key = 'subscription_id'
  self.table_name = 'subscriptions'

  belongs_to :user
  belongs_to :message

  validates :user_id, :message_id, presence: true
  validates :message_id, uniqueness: { scope: :user_id }
end

# eof
