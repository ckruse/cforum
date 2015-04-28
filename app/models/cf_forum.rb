# -*- encoding: utf-8 -*-

class CfForum < ActiveRecord::Base
  self.primary_key = 'forum_id'
  self.table_name  = 'forums'

  has_many :threads, class_name: 'CfThread', :foreign_key => :forum_id, :dependent => :destroy

  has_many :tags, class_name: 'CfTag', :foreign_key => :forum_id, :dependent => :destroy

  has_many :forums_groups_permissions, class_name: 'CfForumGroupPermission', :foreign_key => :forum_id, :dependent => :destroy

  validates :slug, uniqueness: true, length: {:in => 1..20}, allow_blank: false, format: {with: /\A[a-z0-9_-]+\z/}
  validates :name, length: {:minimum => 3}, allow_blank: false
  validates :short_name, length: {:in => 1..50}

  def to_param
    slug
  end

  def moderator?(user)
    return false if user.blank?
    return true if user.admin?
    return true if user.has_badge?(RightsHelper::MODERATOR_TOOLS)

    permissions = CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    permissions.each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE
    end

    return false
  end

  def write?(user)
    return true if standard_permission == CfForumGroupPermission::ACCESS_WRITE
    return false if user.blank?
    return true if standard_permission == CfForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if user.admin?
    return true if user.has_badge?(RightsHelper::MODERATOR_TOOLS)

    permissions = CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    permissions.each do |p|
      return true if p.permission == CfForumGroupPermission::ACCESS_MODERATE or p.permission == CfForumGroupPermission::ACCESS_WRITE
    end

    return false
  end

  def read?(user)
    return true if standard_permission == CfForumGroupPermission::ACCESS_READ or standard_permission == CfForumGroupPermission::ACCESS_WRITE
    return false if user.blank?
    return true if standard_permission == CfForumGroupPermission::ACCESS_KNOWN_READ or standard_permission == CfForumGroupPermission::ACCESS_KNOWN_WRITE
    return true if user.admin?
    return true if user.has_badge?(RightsHelper::MODERATOR_TOOLS)

    permissions = CfForumGroupPermission
      .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum_id)

    return true unless permissions.blank?
    return false
  end

  #default_scope where('public = true')

  def self.visible_sql(user)
    sql = ''

    if user
      if user.admin?
        sql = "SELECT forum_id FROM forums"
      else
        sql = "
        SELECT
            DISTINCT forums.forum_id
          FROM
              forums
            INNER JOIN
              forums_groups_permissions USING(forum_id)
            INNER JOIN
              groups_users USING(group_id)
          WHERE
              (standard_permission = 'read' OR standard_permission = 'write')
            OR
              (
                (
                    permission = 'read'
                  OR
                    permission = 'write'
                  OR
                    permission = 'moderate'
                )
                AND
                  user_id = #{user.user_id}
              )
        "
      end
    else
      sql = "SELECT forum_id FROM forums WHERE standard_permission = 'read' OR standard_permission = 'write'"
    end

    sql
  end

end

# eof
