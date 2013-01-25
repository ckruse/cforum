require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include Devise::TestHelpers
  include CForum::Tools

  def to_params_hash(msg)
    parts = msg.thread.slug.split '/'
    {curr_forum: msg.forum.slug, year: parts[1], mon: parts[2], day: parts[3], tid: parts[4], mid: msg.message_id}
  end
end

# eof