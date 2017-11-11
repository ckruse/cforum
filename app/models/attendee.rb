class Attendee < ApplicationRecord
  self.primary_key = 'attendee_id'

  validates :name, :planned_arrival, presence: true
  validates :user_id, uniqueness: { scope: :event_id, allow_blank: true }

  belongs_to :event
  belongs_to :user
end

# eof
