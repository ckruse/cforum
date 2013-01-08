# -*- coding: utf-8 -*-

class SecuredName < ActiveRecord::Base
  self.primary_key = 'secured_name_id'
  self.table_name  = 'secured_names'

  attr_accessible :secured_name_id, :user_id, :name

  belongs_to :user, :class => 'CfUser', :foreign_key => :user_id
end

# eof
