class CfSetting
  include Mongoid::Document

  #set_collection_name :settings
  store_in collection: 'settings'

  field :user, type: String, default: nil
  field :value
end

# eof
