# -*- encoding: utf-8 -*-

class CfForumGroupPermission < ActiveRecord::Base
  self.primary_key = 'forum_group_permission_id'
  self.table_name  = 'forums_groups_permissions'

  belongs_to :group, class_name: 'CfGroup', :foreign_key => :group_id
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  attr_accessible :forum_group_permission_id, :permission, :group_id, :forum_id

  validates_presence_of :permission, :group_id, :forum_id
end

# eof
