# -*- coding: utf-8 -*-

class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['cjk@defunct.ch']
  end
end

if Rails.env.test? || Rails.env.development?
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end

# eof
