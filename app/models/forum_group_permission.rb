# -*- encoding: utf-8 -*-

class ForumGroupPermission < ActiveRecord::Base
  ACCESS_MODERATE = 'moderate'
  ACCESS_WRITE    = 'write'
  ACCESS_READ     = 'read'

  ACCESS_KNOWN_WRITE = 'known-write'
  ACCESS_KNOWN_READ  = 'known-read'

  PERMISSIONS = [
    ACCESS_MODERATE, ACCESS_WRITE, ACCESS_READ,
    ACCESS_KNOWN_WRITE, ACCESS_KNOWN_READ
  ]

  self.primary_key = 'forum_group_permission_id'
  self.table_name  = 'forums_groups_permissions'

  belongs_to :group, foreign_key: :group_id
  belongs_to :forum

  validates_presence_of :permission, :group_id, :forum_id
  validates :permission, inclusion: PERMISSIONS
end

# eof
