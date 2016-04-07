# -*- coding: utf-8 -*-

class BadgeBadgeGroup < ActiveRecord::Base
  self.primary_key = 'badges_badge_group_id'
  self.table_name  = 'badges_badge_groups'

  belongs_to :badge
  belongs_to :badge_group

  validates_presence_of :badge_id
  validates_presence_of :badge_group_id, on: :update
end

# eof
