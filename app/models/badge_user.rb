class BadgeUser < ApplicationRecord
  self.primary_key = 'badge_user_id'
  self.table_name  = 'badges_users'

  belongs_to :user
  belongs_to :badge
end

# eof
