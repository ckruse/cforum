# -*- coding: utf-8 -*-

class Event < ActiveRecord::Base
  include ParserHelper

  self.primary_key = 'event_id'

  validates_presence_of :name, :description, :start_date, :end_date

  has_many :attendees, ->{ order(:name) }

  def get_content
    description.to_s
  end

  def id_prefix
    'event-'
  end

  def is_attendee(user)
    return if user.blank?
    attendees.find { |u| user.user_id == u.user_id }
  end

  def is_open?
    return false unless visible
    return false if end_date < Date.today
    true
  end
end

# eof
