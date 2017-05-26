# -*- encoding: utf-8 -*-

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
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

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
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

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
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
                    .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?',
                           user.user_id, forum_id)

    return true unless permissions.blank?
    false
  end

  # default_scope where('public = true')

  def self.visible_sql(user = nil)
    perm_list = (ForumGroupPermission::PERMISSIONS.map { |p| "'" + p + "'" }).join(', ')

    if user
      if user.admin?
        'SELECT forum_id FROM forums'
      else
        "
              SELECT
                  DISTINCT forums.forum_id
                FROM
                    forums
                  LEFT JOIN
                    forums_groups_permissions USING(forum_id)
                  LEFT JOIN
                    groups_users USING(group_id)
                WHERE
                    (standard_permission IN (#{perm_list}))
                  OR
                    (
                        permission IN (#{perm_list})
                      AND
                        user_id = #{user.user_id}
                    )
              "
      end
    else
      "SELECT forum_id FROM forums WHERE standard_permission = 'read' OR " \
      " standard_permission = 'write' or standard_permission = 'moderate'"
    end
  end
end

# eof
