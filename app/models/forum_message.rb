class ForumMessage
  include MongoMapper::EmbeddedDocument

  key :id, String
  key :subject, String
  key :category, String
  key :date, Date
  key :content, String

  key :flags, Hash

  one :author

  many :messages, :class_name => 'ForumMessage'
end

# eof
