class Group < ApplicationRecord
  self.primary_key = 'group_id'
  self.table_name  = 'groups'

  has_many :group_users, foreign_key: :group_id, dependent: :destroy
  has_many :users, through: :group_users

  has_many :forums_groups_permissions, class_name: 'ForumGroupPermission', foreign_key: :group_id, dependent: :destroy

  validates :name, presence: true, length: { in: 2..255 }, uniqueness: true
end

# eof
