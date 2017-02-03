# -*- encoding: utf-8 -*-

class MessageTag < ApplicationRecord
  self.primary_key = 'message_tag_id'
  self.table_name  = 'messages_tags'

  belongs_to :message
  belongs_to :tag

  validates_presence_of :message_id, :tag_id
end

# eof
