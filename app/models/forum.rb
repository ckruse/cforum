 # -*- encoding: utf-8 -*-

class Forum < ActiveRecord::Base
  self.primary_key = 'forum_id'
  self.table_name  = 'forums'

  has_many :threads, class_name: 'CfThread', foreign_key: :forum_id, dependent: :destroy
  has_many :messages, foreign_key: :forum_id, dependent: :delete_all

  has_many :tags, foreign_key: :forum_id, dependent: :destroy

  has_many :forums_groups_permissions, class_name: 'ForumGroupPermission', foreign_key: :forum_id, dependent: :destroy

  validates :slug, uniqueness: true, length: {in: 1..20}, allow_blank: false, format: {with: /\A[a-z0-9_-]+\z/}
  validates :name, length: {minimum: 3}, allow_blank: false
  validates :short_name, length: {in: 1..50}

  def to_param
    slug
  end

  def moderator?(user)
    return false if user.blank?
    return true if user.admin?
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    permissions.each do |p|
      return true if p.permission == ForumGroupPermission::ACCESS_MODERATE
    end

    return false
  end

  def write?(user)
    return true if standard_permission == ForumGroupPermission::ACCESS_WRITE
    return false if user.blank?
    return true if standard_permission == ForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if user.admin?
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    permissions.each do |p|
      return true if p.permission == ForumGroupPermission::ACCESS_MODERATE or p.permission == ForumGroupPermission::ACCESS_WRITE
    end

    return false
  end

  def read?(user)
    return true if standard_permission == ForumGroupPermission::ACCESS_READ or standard_permission == ForumGroupPermission::ACCESS_WRITE
    return false if user.blank?
    return true if standard_permission == ForumGroupPermission::ACCESS_KNOWN_READ or standard_permission == ForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if user.admin?
    return true if user.has_badge?(Badge::MODERATOR_TOOLS)

    permissions = ForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    return true unless permissions.blank?
    return false
  end

  #default_scope where('public = true')

  def self.visible_sql(user = nil)
    sql = ''
    perm_list = (ForumGroupPermission::PERMISSIONS.map { |p| "'" + p + "'" }).join(", ")

    if user
      if user.admin?
        sql = "SELECT forum_id FROM forums"
      else
        sql = "
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
      sql = "SELECT forum_id FROM forums WHERE standard_permission = 'read' OR standard_permission = 'write' or standard_permission = 'moderate'"
    end

    sql
  end

end

# eof
