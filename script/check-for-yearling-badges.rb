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

User.order(:user_id).all.each do |user|
  yearling = Badge.where(slug: 'yearling').first!
  last_yearling = BadgeUser
                    .where(user_id: user.user_id,
                           badge_id: yearling.badge_id)
                    .order(created_at: :desc)
                    .first

  difference = if last_yearling.blank?
                 DateTime.now - user.created_at.to_datetime
               else
                 DateTime.now - last_yearling.created_at.to_datetime
               end

  years = (difference / 365).floor
  years = 0 if years < 0

  years.times do
    give_badge(user, yearling)
  end
end

# eof
