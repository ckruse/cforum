# -*- encoding: utf-8 -*-

class GroupUser < ActiveRecord::Base
  self.primary_key = 'group_user_id'
  self.table_name  = 'groups_users'

  belongs_to :user
  belongs_to :group

  validates_presence_of :user_id, :group_id
end

# eof
