class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :confirmable, :trackable

  has_attached_file :avatar, styles: { medium: '80x80>', thumb: '20x20>' }, default_url: '/images/:style/missing.png'
  validates_attachment_content_type :avatar, content_type: %r{\Aimage/.*\Z}

  self.primary_key = 'user_id'
  self.table_name  = 'users'

  validates :password, presence: { on: :create }
  validates :password, length: { minimum: 3 }, confirmation: true, if: :password, allow_blank: true
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[^@]+\z/, message: I18n.t('users.no_at_in_name') }, length: { in: 2..255 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, email: true, length: { in: 2..255 }

  attr_accessor :login

  has_one :settings, class_name: 'Setting', foreign_key: :user_id, dependent: :destroy

  has_many :group_users, foreign_key: :user_id, dependent: :delete_all
  has_many :groups, through: :group_users

  has_many :badge_users, -> { order(:created_at) }, dependent: :delete_all,
                                                    foreign_key: :user_id
  has_many :badges, through: :badge_users

  has_many :messages, foreign_key: :user_id, dependent: :nullify

  has_many :subscriptions, dependent: :delete_all

  def conf(nam)
    vals = settings.options if settings.present?
    vals ||= {}

    vals[nam.to_s] || ConfigManager::DEFAULTS[nam]
  end

  def self.find_first_by_auth_conditions(conditions = {})
    conditions = conditions.dup
    conditions[:active] = true
    conditions.permit! if conditions.is_a?(ActionController::Parameters)

    login = conditions.delete(:login)

    if login
      where(conditions).find_by(['LOWER(username) = :value OR LOWER(email) = :value', { value: login.downcase }])
    else
      find_by(conditions)
    end
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def badge?(type)
    badges.each do |b|
      return true if b.badge_type == type
    end

    false
  end

  def moderate?(forum = nil)
    return true if admin?
    return true if badge?(Badge::MODERATOR_TOOLS)
    return false if forum.blank?

    @permissions ||= {}
    @permissions[forum.forum_id] ||= ForumGroupPermission
                                       .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) ' \
                                              'AND forum_id = ?', user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if p.permission == ForumGroupPermission::MODERATE
    end

    false
  end

  def moderator?
    return true if admin?
    return true if badge?(Badge::MODERATOR_TOOLS)

    @is_moderator ||=
      ForumGroupPermission.exists?(['group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) ' \
                                    'AND permission = ?', user_id, ForumGroupPermission::MODERATE])
  end

  def write?(forum)
    return true if forum.standard_permission == ForumGroupPermission::WRITE
    return true if forum.standard_permission == ForumGroupPermission::KNOWN_WRITE
    return true if admin?
    return true if badge?(Badge::MODERATOR_TOOLS)

    @permissions ||= {}
    @permissions[forum.forum_id] ||= ForumGroupPermission
                                       .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) ' \
                                              'AND forum_id = ?', user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if (p.permission == ForumGroupPermission::MODERATE) ||
                     (p.permission == ForumGroupPermission::WRITE)
    end

    false
  end

  def read?(forum)
    return true if (forum.standard_permission == ForumGroupPermission::READ) ||
                   (forum.standard_permission == ForumGroupPermission::WRITE)

    return true if (forum.standard_permission == ForumGroupPermission::KNOWN_READ) ||
                   (forum.standard_permission == ForumGroupPermission::KNOWN_WRITE)

    return true if admin?
    return true if badge?(Badge::MODERATOR_TOOLS)

    @permissions ||= {}
    @permissions[forum.forum_id] ||= ForumGroupPermission
                                       .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) ' \
                                              'AND forum_id = ?', user_id, forum.forum_id)

    @permissions[forum.forum_id].each do |p|
      return true if (p.permission == ForumGroupPermission::MODERATE) ||
                     (p.permission == ForumGroupPermission::WRITE) ||
                     (p.permission == ForumGroupPermission::READ)
    end

    false
  end

  def thumb
    avatar(:thumb)
  end

  def serializable_hash(options = {})
    options ||= {}
    options[:except] ||= []
    options[:except] += %i[encrypted_password authentication_token email]
    super(options)
  end

  def audit_json
    as_json(include: :badges)
  end

  def unique_badges
    unique_badges = {}
    badge_users.each do |ub|
      unique_badges[ub.badge_id] ||= { badge: ub.badge, created_at: ub.created_at, times: 0 }
      unique_badges[ub.badge_id][:times] += 1
    end

    unique_badges.values.sort_by { |a| a[:created_at] }
  end
end

# eof
