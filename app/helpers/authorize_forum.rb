# -*- coding: utf-8 -*-

module AuthorizeForum
  def authorize!
    forum = current_forum

    if params.has_key?(:view_all)
      if forum.blank?
        @view_all = true if not current_user.blank? and current_user.admin?
      else
        @view_all = forum.moderator?(current_user)
      end
    end

    return if forum.blank?

    return if %q{show index}.include?(action_name) and forum.read?(current_user)
    return if %q{new create}.include?(action_name) and forum.write?(current_user)
    return if forum.moderator?(current_user)

    raise CForum::ForbiddenException.new
  end
end

# eof
