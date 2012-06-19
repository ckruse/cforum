class ForumThread
  include MongoMapper::Document

  set_collection_name :threads

  key :tid, String
  key :archived, Boolean

  many :messages
end

# eof
