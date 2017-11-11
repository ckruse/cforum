class BadgeBadgeGroup < ApplicationRecord
  self.primary_key = 'badges_badge_group_id'
  self.table_name  = 'badges_badge_groups'

  belongs_to :badge
  belongs_to :badge_group

  validates :badge_id, presence: true
  validates :badge_group_id, presence: { on: :update }
end

# eof
