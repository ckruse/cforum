# -*- coding: utf-8 -*-

module Admin
  module AuthorizeHelper
    def authorize!
      return if current_user and current_user.admin?
      raise CForum::ForbiddenException.new
    end
  end
end

# eof