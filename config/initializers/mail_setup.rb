# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'development_mail_interceptor.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'tools.rb')

ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?

# eof
