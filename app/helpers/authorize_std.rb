# -*- coding: utf-8 -*-

module AuthorizeStd
  def check_forum_access
    forum = current_forum
    user = current_user

    return if forum.blank?
    return if user and user.admin

    return if forum.read?(user)
    if %w{new create}.include?(action_name)
      return if forum.write?(user)
    elsif %w{edit update destroy}.include?(action_name)
      return if forum.moderate?(user)
    end

    raise CForum::ForbiddenException.new
  end
end

# eof
