class CfUser
  include Mongoid::Document

  authenticates_with_sorcery!

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create

  validates_presence_of :username
  validates_uniqueness_of :username

  store_in collection: "users"
  #set_collection_name :users

  field :username, type: String
  field :email, type: String

  field :crypted_password, type: String
  field :salt, type: String

  field :last_login_at, type: Time
  field :last_logout_at, type: Time

  field :settings, type: Hash
  field :storage, type: Hash
end

# eof
