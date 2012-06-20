module CForum
  class Thread
    include MongoMapper::Document

    set_collection_name :threads

    key :tid, String
    key :archived, Boolean

    many :messages, :class_name => 'CForum::Message'
  end
end

# eof
