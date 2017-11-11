#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require File.join(File.dirname(__FILE__), '..', 'lib', 'peon')
require File.join(File.dirname(__FILE__), '..', 'lib', 'peon', 'grunt')

# TODO: add support for pathes below root
def badge_path(b)
  '/badges/' + b.slug
end

p = Peon::Tasks::PeonTask.new

BadgeUser.transaction do
  BadgeUser.delete_all
  badges = Badge.all

  User.all.each do |u|
    badges.each do |b|
      next unless u.score >= b.score_needed
      u.badge_users.create(badge_id: b.badge_id)
      p.notify_user(
        u, '', I18n.t('badges.badge_won',
                      name: b.name,
                      mtype: I18n.t('badges.badge_medal_types.' + b.badge_medal_type)),
        badge_path(b), b.badge_id, 'badge'
      )
    end
  end
end

# eof
