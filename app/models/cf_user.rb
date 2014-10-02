# -*- encoding: utf-8 -*-

class CfUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :confirmable, :trackable

  self.primary_key = 'user_id'
  self.table_name  = 'users'


  validates_presence_of :password, :on => :create
  validates :password, length: {:minimum => 3}, confirmation: true, :if => :password, allow_blank: true
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, email: true

  attr_accessor :login

  has_one :settings, class_name: 'CfSetting', :foreign_key => :user_id, :dependent => :destroy

  has_many :groups_users, class_name: 'CfGroupUser', :foreign_key => :user_id
  has_many :groups, class_name: 'CfGroup', :through => :groups_users

  def conf(nam, default = nil)
    vals = settings.options unless settings.blank?
    vals ||= {}

    vals[nam.to_s] || default
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

    @permissions ||= {}
    @permissions[forum.forum_id] ||= CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE
    end

    return false
  end

  def write?(forum)
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_WRITE
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if admin?

    @permissions ||= {}
    @permissions[forum.forum_id] ||= CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE or p.permission == CfForumGroupPermission::ACCESS_WRITE
    end

    return false
  end

  def read?(forum)
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_READ or forum.standard_permission == CfForumGroupPermission::ACCESS_WRITE
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_KNOWN_READ or forum.standard_permission == CfForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if admin?

    @permissions ||= {}
    @permissions[forum.forum_id] ||= CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE or p.permission == CfForumGroupPermission::ACCESS_WRITE or p.permission == CfForumGroupPermission::ACCESS_READ
    end

    return false
  end

  def score
    unless @score
      @score = CfScore.where(user_id: self.user_id).sum('value')
    end

    @score
  end
end

# eof
