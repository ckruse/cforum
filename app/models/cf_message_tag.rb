# -*- encoding: utf-8 -*-

class CfMessageTag < ActiveRecord::Base
  self.primary_key = 'message_tag_id'
  self.table_name  = 'messages_tags'

  belongs_to :message, class_name: 'CfMessage', :foreign_key => :message_id
  belongs_to :tag, class_name: 'CfTag', :foreign_key => :tag_id

  validates_presence_of :message_id, :tag_id
end

# eof
