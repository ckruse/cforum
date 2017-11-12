class Event < ApplicationRecord
  include ParserHelper

  self.primary_key = 'event_id'

  validates :name, :description, :start_date, :end_date, presence: true

  has_many :attendees, -> { order(:name) }

  def md_content
    description.to_s
  end

  def id_prefix
    'event-'
  end

  def attendee?(user)
    return if user.blank?
    attendees.find { |u| user.user_id == u.user_id }
  end

  def open?
    return false unless visible
    return false if end_date < Time.zone.today
    true
  end
end

# eof
