# -*- coding: utf-8 -*-

module AuthorizeStd
  def check_forum_access
    forum = current_forum
    user = current_user

    return if forum.blank?
    return if forum.public
    return if user and user.admin

    unless user.blank?
      permissions = CfForumGroupPermission
        .where("group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) AND forum_id = ?", user.user_id, forum.forum_id)
        .all

      permissions.each do |p|
        if %w{new edit create update destroy}.include?(action_name)
          return if [CfForumGroupPermission::ACCESS_MODERATE, CfForumGroupPermission::ACCESS_WRITE].include?(p.permission)
        else
          return if [CfForumGroupPermission::ACCESS_MODERATE, CfForumGroupPermission::ACCESS_WRITE, CfForumGroupPermission::ACCESS_READ].include?(p.permission)
        end
      end

    end

    raise CForum::ForbiddenException.new
  end
end

# eof
