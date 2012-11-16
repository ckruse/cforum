# -*- encoding: utf-8 -*-

class CfUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :timeoutable, :confirmable

  self.primary_key = 'user_id'
  self.table_name  = 'cforum.users'

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create

  validates_presence_of :username, :email
  validates_uniqueness_of :username, :email

  validates_confirmation_of :password, :if => :password
  validates_length_of :password, :minimum => 3, :if => :password, :allow_blank => true

  attr_accessible :username, :email, :password, :password_confirmation,
    :admin, :active, :created_at,
    :updated_at, :confirmed_at, :remember_me

  attr_accessor :login

  has_one :settings, class_name: 'CfSetting', :foreign_key => :user_id, :dependent => :destroy
  has_many :rights, class_name: 'CfForumPermission', :foreign_key => :user_id
  has_many :forums, class_name: 'CfForum', :through => :rights

  def conf(nam, default = nil)
    vals = settings.options unless settings.blank?
    vals ||= {}

    vals[nam.to_s] || default
  end

  def to_param
    username
  end

  def self.find_first_by_auth_conditions(conditions = {})
    conditions = conditions.dup
    conditions[:active] = true

    if login = conditions.delete(:login)
      where(conditions).where(["LOWER(username) = :value OR LOWER(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def moderate?(forum)
    return true if admin?

    rights.each do |r|
      return true if r.forum_id == forum.forum_id and r.permission == 'moderate'
    end

    return false
  end

  def write?(forum)
    return true if forum.public?
    return true if admin?

    rights.each do |r|
      return true if r.forum_id == forum.forum_id and (r.permission == 'write' or r.permission == 'moderate')
    end

    return false
  end

  def read?(forum)
    return true if forum.public?
    return true if admin?

    rights.each do |r|
      return true if r.forum_id == forum.forum_id
    end

    return false
  end
end

# eof
