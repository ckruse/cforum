class GroupUser < ApplicationRecord
  self.primary_key = 'group_user_id'
  self.table_name  = 'groups_users'

  belongs_to :user
  belongs_to :group

  validates :user_id, :group_id, presence: true
end

# eof
