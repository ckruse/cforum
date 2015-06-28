# -*- coding: utf-8 -*-

class CfCite < ActiveRecord::Base
  self.primary_key = 'cite_id'
  self.table_name  = 'cites'

  belongs_to :message, class_name: 'CfMessage'
  belongs_to :user, class_name: 'CfUser'

  validates :author, length: { in: 2..60 }, allow_blank: true
  validates :cite, length: { in: 10..12288 }, presence: true
end

# eof
