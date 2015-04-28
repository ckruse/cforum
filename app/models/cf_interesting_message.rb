# -*- coding: utf-8 -*-

class CfInterestingMessage < ActiveRecord::Base
  self.primary_key = 'interesting_message_id'
  self.table_name  = 'interesting_messages'

  belongs_to :message, class: CfMessage
  belongs_to :user, class: CfUser
end

# eof
