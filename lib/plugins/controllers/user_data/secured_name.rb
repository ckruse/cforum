# -*- coding: utf-8 -*-

class SecuredName < ActiveRecord::Base
  self.primary_key = 'user_id'
  self.table_name  = 'secured_names'

  attr_accessible :user_id, :name

  belongs_to :user, class_name: 'CfUser', :foreign_key => :user_id
end

# eof
