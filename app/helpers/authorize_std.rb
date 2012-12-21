# -*- coding: utf-8 -*-

module AuthorizeStd
  def check_forum_access
    forum = current_forum
    user = current_user

    return if forum.blank?
    return if forum.public
    return if user and user.admin

    unless user.blank?
      user.rights.each do |r|
        if r.forum_id == forum.forum_id
          if %w{new edit create update destroy}.include?(action_name)
            return if %w{moderator write}.include?(r.permission)
          else
            return if %w{moderator read write}.include?(r.permission)
          end
        end
      end
    end

    raise CForum::ForbiddenException.new
  end
end

# eof
