require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'tools.rb')

class ActionMailer::Base
  include CForum::Tools
end

# eof
