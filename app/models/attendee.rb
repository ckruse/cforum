# -*- coding: utf-8 -*-

class Attendee < ActiveRecord::Base
  self.primary_key = 'attendee_id'

  validates_presence_of :name, :planned_arrival
  validates_uniqueness_of :user_id, scope: :event_id

  belongs_to :event
  belongs_to :user
end

# eof
