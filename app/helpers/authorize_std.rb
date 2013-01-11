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
        .where("group_id IN (SELECT group_id FROM users_groups WHERE user_id = ?) AND forum_id = ?", user.user_id, forum.forum_id)
        .all

      permissions.each do |p|
        if %w{new edit create update destroy}.include?(action_name)
          return if %w{moderator write}.include?(p.permission)
        else
          return if %w{moderator read write}.include?(p.permission)
        end
      end

    end

    raise CForum::ForbiddenException.new
  end
end

# eof
