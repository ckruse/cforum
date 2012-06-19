class User
  set_collection_name :threads

  key :username, String
  key :pass_hash, String
end

# eof
