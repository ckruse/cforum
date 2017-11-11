class ForumGroupPermission < ApplicationRecord
  MODERATE = 'moderate'.freeze
  WRITE    = 'write'.freeze
  READ     = 'read'.freeze

  KNOWN_WRITE = 'known-write'.freeze
  KNOWN_READ  = 'known-read'.freeze

  PERMISSIONS = [MODERATE, WRITE, READ, KNOWN_WRITE, KNOWN_READ].freeze

  self.primary_key = 'forum_group_permission_id'
  self.table_name  = 'forums_groups_permissions'

  belongs_to :group, foreign_key: :group_id
  belongs_to :forum

  validates :permission, :group_id, :forum_id, presence: true
  validates :permission, inclusion: PERMISSIONS
end

# eof
