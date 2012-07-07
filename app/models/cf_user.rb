class CfUser < ActiveRecord::Base
  authenticates_with_sorcery!

  self.primary_key = 'user_id'
  self.table_name  = 'cforum.users'

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create

  validates_presence_of :username
  validates_uniqueness_of :username

  validates_confirmation_of :password, :if => :password
  validates_length_of :password, :minimum => 3, :if => :password, :allow_blank => true

  attr_accessible :username, :email, :crypted_password, :salt,
    :password, :password_confirmation, :admin, :active,
    :created_at, :updated_at, :last_login_at, :last_logout_at

  has_many :settings, class_name: 'CfSetting'
  has_many :forum_mods, class_name: 'CfModerator', :foreign_key => :user_id
  has_many :forums, class_name: 'CfForum', :through => :forum_mods

  def to_param
    username
  end
end

# eof
