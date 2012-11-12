# -*- encoding: utf-8 -*-

class CfForumAccess < ActiveRecord::Base
  ACCESS_READ      = 'read'
  ACCESS_WRITE     = 'write'
  ACCESS_MODERATOR = 'moderator'

  self.primary_key = 'forum_access_id'
  self.table_name  = 'cforum.forum_access'

  belongs_to :user, class_name: 'CfUser'
  belongs_to :forum, class_name: 'CfForum'

  attr_accessible :forum_access_id, :user_id, :forum_id,
    :permission
end


# eof