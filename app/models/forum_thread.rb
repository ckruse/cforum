class ForumThread
  include MongoMapper::Document

  set_collection_name :threads

  key :tid, String
  key :archived, Boolean

  many :messages, :class_name => 'ForumMessage'
end

# eof
