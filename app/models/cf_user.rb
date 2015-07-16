# -*- encoding: utf-8 -*-

class CfUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :confirmable, :trackable

  has_attached_file :avatar, styles: { medium: "80x80>", thumb: "20x20>" }, default_url: "/images/:style/missing.png"
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  self.primary_key = 'user_id'
  self.table_name  = 'users'


  validates_presence_of :password, on: :create
  validates :password, length: {minimum: 3}, confirmation: true, if: :password, allow_blank: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, email: true

  attr_accessor :login

  has_one :settings, class_name: 'CfSetting', foreign_key: :user_id, dependent: :destroy

  has_many :groups_users, class_name: 'CfGroupUser', foreign_key: :user_id
  has_many :groups, class_name: 'CfGroup', through: :groups_users

  has_many :badges_users, class_name: CfBadgeUser, dependent: :delete_all,
           foreign_key: :user_id
  has_many :badges, through: :badges_users

  def conf(nam)
    vals = settings.options unless settings.blank?
    vals ||= {}

    vals[nam.to_s] || ConfigManager::DEFAULTS[nam]
  end

  def self.find_first_by_auth_conditions(conditions = {})
    conditions = conditions.dup
    conditions[:active] = true
    conditions.permit! if conditions.is_a?(ActionController::Parameters)

    if login = conditions.delete(:login)
      where(conditions).where(["LOWER(username) = :value OR LOWER(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def after_database_authentication
    if websocket_token.blank?
      update_attributes(websocket_token: SecureRandom.uuid)
    end
  end

  def has_badge?(type)
    badges.each do |b|
      return true if b.badge_type == type
    end

    return false
  end

  def moderate?(forum = nil)
    return true if admin?
    return true if has_badge?(RightsHelper::MODERATOR_TOOLS)
    return false if forum.blank?

    @permissions ||= {}
    @permissions[forum.forum_id] ||= CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE
    end

    return false
  end

  def moderator?
    return true if admin?
    return true if has_badge?(RightsHelper::MODERATOR_TOOLS)

    return CfForumGroupPermission.exists?(["group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND permission = ?",
                                           user_id, CfForumGroupPermission::ACCESS_MODERATE])
  end

  def write?(forum)
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_WRITE
    return true if forum.standard_permission == CfForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if admin?
    return true if has_badge?(RightsHelper::MODERATOR_TOOLS)

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
    return true if has_badge?(RightsHelper::MODERATOR_TOOLS)

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

  def thumb
    avatar(:thumb)
  end

  def serializable_hash(options = {})
    options[:except] ||= []
    options[:except] += [:encrypted_password, :websocket_token, :authentication_token, :email]
    super(options)
  end
end

# eof
