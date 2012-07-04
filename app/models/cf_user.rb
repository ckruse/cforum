class CfUser < ActiveRecord::Base
  authenticates_with_sorcery!

  self.primary_key = 'user_id'
  self.table_name  = 'cforum.users'

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create

  validates_presence_of :username
  validates_uniqueness_of :username

  attr_accessible :username, :email, :crypted_password, :salt, :created_at, :updated_at, :last_login_at, :last_logout_at

  has_many :settings, class_name: 'CfSetting'
end

# eof
