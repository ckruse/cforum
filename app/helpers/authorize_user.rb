# -*- coding: utf-8 -*-

module AuthorizeUser
  def authorize!
    raise CForum::ForbiddenException.new if current_user.blank?
  end
end

# eof
