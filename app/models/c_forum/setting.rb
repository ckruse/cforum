module CForum
  class Setting
    include MongoMapper::Document

    set_collection_name :settings

    key :user, String, :default => nil
    key :value
  end
end

# eof
