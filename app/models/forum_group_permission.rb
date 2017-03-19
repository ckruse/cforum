# -*- encoding: utf-8 -*-

class ForumGroupPermission < ApplicationRecord
  ACCESS_MODERATE = 'moderate'.freeze
  ACCESS_WRITE    = 'write'.freeze
  ACCESS_READ     = 'read'.freeze

  ACCESS_KNOWN_WRITE = 'known-write'.freeze
  ACCESS_KNOWN_READ  = 'known-read'.freeze

  PERMISSIONS = [
    ACCESS_MODERATE, ACCESS_WRITE, ACCESS_READ,
    ACCESS_KNOWN_WRITE, ACCESS_KNOWN_READ
  ].freeze

  self.primary_key = 'forum_group_permission_id'
  self.table_name  = 'forums_groups_permissions'

  belongs_to :group, foreign_key: :group_id
  belongs_to :forum

  validates_presence_of :permission, :group_id, :forum_id
  validates :permission, inclusion: PERMISSIONS
end

# eof
