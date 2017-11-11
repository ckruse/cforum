class BadgeGroup < ApplicationRecord
  self.primary_key = 'badge_group_id'
  self.table_name  = 'badge_groups'

  has_many :badge_badge_groups, dependent: :delete_all
  has_many :badges, -> { order(:order) }, through: :badge_badge_groups

  validates :name, presence: true, length: { in: 2..255 }, allow_blank: false, uniqueness: { case_sensitive: false }
end

# eof
