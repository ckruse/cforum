module CForum
  class User
    include MongoMapper::Document

    set_collection_name :users

    key :username, String
    key :pass_hash, String
  end
end

# eof
