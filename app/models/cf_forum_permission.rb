# -*- encoding: utf-8 -*-

class CfForumPermission < ActiveRecord::Base
  ACCESS_READ      = 'read'
  ACCESS_WRITE     = 'write'
  ACCESS_MODERATOR = 'moderator'

  self.primary_key = 'forum_permission_id'
  self.table_name  = 'cforum.forum_permissions'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :forum, class_name: 'CfForum'

  attr_accessible :forum_permission_id, :user_id, :forum_id, :permission
end


# eof