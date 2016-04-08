# -*- coding: utf-8 -*-

class MessageReference < ActiveRecord::Base
  self.primary_key = 'message_reference_id'
  self.table_name  = 'message_references'

  belongs_to :src_message, foreign_key: :src_message_id
  belongs_to :dst_message, foreign_key: :dst_message_id
end

# eof
