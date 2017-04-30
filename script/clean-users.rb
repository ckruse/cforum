#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')
require File.join(dir, '..', 'lib', 'script_helpers.rb')

include CForum::Tools
include ReferencesHelper
include ScriptHelpers
include AuditHelper

$config_manager = ConfigManager.new

users = User.where("confirmed_at IS NULL AND confirmation_sent_at <= NOW() - INTERVAL '7 days'")
users.each do |u|
  Rails.logger.info 'CleanupUsersTask: deleting user ' + u.username + ' because it is unconfirmed for longer than 7 days'

  User.transaction do
    audit(u, 'autodestroy', nil)
    u.destroy
  end
end

# eof
