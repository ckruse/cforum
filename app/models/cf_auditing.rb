# -*- coding: utf-8 -*-

class CfAuditing < ActiveRecord::Base
  self.primary_key = 'auditing_id'
  self.table_name  = 'auditing'

  belongs_to :user

  validates_presence_of :relation, :relid, :act, :contents
end

# eof
