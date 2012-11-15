# -*- coding: utf-8 -*-

module AuthorizeForum
  def authorize!
    forum = current_forum

    if params.has_key?(:view_all)
      raise CForum::ForbiddenException.new unless forum.moderator?(current_user)
    end

    return if forum.public? and %w{show index new create}.include?(action_name)
    return if %w{show index}.include?(action_name) and forum.read?(current_user)
    return if %w{edit new create update}.include?(action_name) and forum.write?(current_user)
    return if forum.moderator?(current_user) or (not current_user.blank? and current_user.admin?)

    raise CForum::ForbiddenException.new
  end
end

# eof