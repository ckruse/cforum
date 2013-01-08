# -*- encoding: utf-8 -*-

class CfGroup < ActiveRecord::Base
  self.primary_key = 'group_id'
  self.table_name  = 'groups'

  has_many :groups_users, class_name: 'CfGroupUser', :foreign_key => :group_id, :dependent => :destroy
  has_many :users, class_name: 'CfUser', :through => :groups_users

  attr_accessible :group_id, :name
end

# eof
