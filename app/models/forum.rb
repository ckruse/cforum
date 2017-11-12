class Forum < ApplicationRecord
  self.primary_key = 'forum_id'
  self.table_name  = 'forums'

  has_many :threads, class_name: 'CfThread', foreign_key: :forum_id, dependent: :destroy
  has_many :messages, foreign_key: :forum_id, dependent: :delete_all

  has_many :tags, foreign_key: :forum_id, dependent: :destroy

  has_many :forums_groups_permissions, class_name: 'ForumGroupPermission', foreign_key: :forum_id, dependent: :destroy

  validates :slug, uniqueness: true, length: { in: 1..20 }, allow_blank: false, format: { with: /\A[a-z0-9_-]+\z/ }
  validates :name, length: { minimum: 3 }, allow_blank: false
  validates :short_name, length: { in: 1..50 }

  def to_param
    slug
  end

  def moderator?(user)
    return false if user.blank?
    return true if user.admin?
    return true if user.badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
                    .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?',
                           user.user_id, forum_id)

    permissions.each do |p|
      return true if p.permission == ForumGroupPermission::MODERATE
    end

    false
  end

  def write?(user)
    return true if standard_permission == ForumGroupPermission::WRITE
    return false if user.blank?
    return true if standard_permission == ForumGroupPermission::KNOWN_WRITE
    return true if user.admin?
    return true if user.badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
                    .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?',
                           user.user_id, forum_id)

    permissions.each do |p|
      if (p.permission == ForumGroupPermission::MODERATE) || (p.permission == ForumGroupPermission::WRITE)
        return true
      end
    end

    false
  end

  def read?(user)
    return true if standard_permission.in?([ForumGroupPermission::READ, ForumGroupPermission::WRITE])
    return false if user.blank?
    return true if standard_permission.in?([ForumGroupPermission::KNOWN_READ, ForumGroupPermission::KNOWN_WRITE])
    return true if user.admin?
    return true if user.badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
                    .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?',
                           user.user_id, forum_id)

    return true if permissions.present?
    false
  end

  # default_scope where('public = true')

  def self.visible_forums(user = nil)
    return Forum.where(standard_permission: %w[read write moderate]).order(:position) if user.blank?
    return Forum.order(:position) if user.admin?

    Forum
      .where(forum_id: Forum
               .joins('LEFT JOIN forums_groups_permissions USING(forum_id)')
               .joins('LEFT JOIN groups_users USING(group_id)')
               .where('standard_permission IN (?) OR (permission IN (?) AND user_id = ?)',
                      ForumGroupPermission::PERMISSIONS, ForumGroupPermission::PERMISSIONS, user.user_id))
      .order(:position)
  end
end

# eof
