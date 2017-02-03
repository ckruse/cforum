# -*- coding: utf-8 -*-

class Attendee < ApplicationRecord
  self.primary_key = 'attendee_id'

  validates_presence_of :name, :planned_arrival
  validates_uniqueness_of :user_id, scope: :event_id, allow_blank: true

  belongs_to :event
  belongs_to :user
end

# eof
