class MessageTag < ApplicationRecord
  self.primary_key = 'message_tag_id'
  self.table_name  = 'messages_tags'

  belongs_to :message
  belongs_to :tag

  validates :message_id, :tag_id, presence: true
end

# eof
