# -*- encoding: utf-8 -*-

class CfGroupUser < ActiveRecord::Base
  self.primary_key = 'group_user_id'
  self.table_name  = 'groups_users'

  belongs_to :user, class_name: 'CfUser', :foreign_key => :user_id
  belongs_to :group, class_name: 'CfGroup', :foreign_key => :group_id

  attr_accessible :group_user_id, :group_id, :user_id

  validates_presence_of :user_id, :group_id
end

# eof
