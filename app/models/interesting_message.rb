class InterestingMessage < ApplicationRecord
  self.primary_key = 'interesting_message_id'
  self.table_name  = 'interesting_messages'

  belongs_to :message
  belongs_to :user
end

# eof
