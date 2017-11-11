class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['cjk@defunct.ch']
  end
end

if Rails.env.development?
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end

# eof
