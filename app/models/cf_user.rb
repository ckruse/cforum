class CfUser
  include MongoMapper::Document

  authenticates_with_sorcery!

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create

  validates_presence_of :username
  validates_uniqueness_of :username

  set_collection_name :users

  key :username, String
  key :email, String

  key :crypted_password, String
  key :salt, String

  key :last_login_at, Time
  key :last_logout_at, Time

  key :settings, Hash
  key :storage, Hash
end

# eof
