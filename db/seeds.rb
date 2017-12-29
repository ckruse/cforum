# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# s = Setting.new(
#   value: %w[
#     CATEGORY1
#     CATEGORY2
#     CATEGORY3
#     CATEGORY4
#   ]
# )
# s.id = 'categories'
# s.save

# s = Setting.new(
#   value: true
# )
# s.id = 'use_archive'
# s.save

unless User.where(username: 'admin').exists?
  usr = User.new(username: 'admin', email: 'foo@example.org', password: 'admin', admin: true)
  usr.skip_confirmation!
  usr.save!(validate: false)
end

unless Forum.where(slug: 'forum-1').exists?
  Forum.create!(name: 'Forum 1', slug: 'forum-1', short_name: 'Forum 1', standard_permission: 'write')
end

WRITER_BADGES = [
  { messages: 100, name: 'chisel', type: 'bronze' },
  { messages: 1000, name: 'brush', type: 'bronze' },
  { messages: 2500, name: 'quill', type: 'bronze' },
  { messages: 5000, name: 'pen', type: 'bronze' },
  { messages: 7500, name: 'printing_press', type: 'bronze' },
  { messages: 10_000, name: 'typewriter', type: 'silver' },
  { messages: 20_000, name: 'matrix_printer', type: 'silver' },
  { messages: 30_000, name: 'inkjet_printer', type: 'silver' },
  { messages: 40_000, name: 'laser_printer', type: 'silver' },
  { messages: 50_000, name: '1000_monkeys', type: 'gold' }
].freeze

SCORE_BADGES = [
  { name: 'donee', type: 'bronze' },
  { name: 'nice_answer', type: 'bronze' },
  { name: 'good_answer', type: 'silver' },
  { name: 'great_answer', type: 'silver' },
  { name: 'superb_answer', type: 'gold' },
  { name: 'controverse', type: 'bronze' },
  { name: 'enthusiast', type: 'bronze' },
  { name: 'critic', type: 'bronze' },
  { name: 'teacher', type: 'bronze' }
].freeze


Badge.create!(score_needed: 50, name: I18n.t('badges.badge_types.upvote'),
              slug: 'upvote', badge_type: 'upvote', badge_medal_type: 'bronze',
              description: I18n.t('badges.default_descs.upvote'))

Badge.create!(score_needed: 200, name: I18n.t('badges.badge_types.downvote'),
              slug: 'downvote', badge_type: 'downvote', badge_medal_type: 'bronze',
              description: I18n.t('badges.default_descs.downvote'))

Badge.create!(score_needed: 500, name: I18n.t('badges.badge_types.retag'),
              slug: 'retag', badge_type: 'retag', badge_medal_type: 'bronze',
              description: I18n.t('badges.default_descs.retag'))

Badge.create!(score_needed: 1000, name: I18n.t('badges.badge_types.visit_close_reopen'),
              slug: 'visit_close_reopen', badge_type: 'visit_close_reopen',
              badge_medal_type: 'bronze',
              description: I18n.t('badges.default_descs.visit_close_reopen'))

Badge.create!(score_needed: 1200, name: I18n.t('badges.badge_types.create_tag'),
              slug: 'create_tag', badge_type: 'create_tag',
              badge_medal_type: 'silver',
              description: I18n.t('badges.default_descs.create_tag'))

Badge.create!(score_needed: 1500, name: I18n.t('badges.badge_types.create_tag_synonym'),
              slug: 'create_tag_synonym', badge_type: 'create_tag_synonym',
              badge_medal_type: 'silver',
              description: I18n.t('badges.default_descs.create_tag_synonym'))

Badge.create!(score_needed: 2000, name: I18n.t('badges.badge_types.edit_question'),
              slug: 'edit_question', badge_type: 'edit_question',
              badge_medal_type: 'silver',
              description: I18n.t('badges.default_descs.edit_question'))

Badge.create!(score_needed: 2500, name: I18n.t('badges.badge_types.edit_answer'),
              slug: 'edit_answer', badge_type: 'edit_answer',
              badge_medal_type: 'silver',
              description: I18n.t('badges.default_descs.edit_answer'))

Badge.create!(score_needed: 3000, name: I18n.t('badges.badge_types.create_close_reopen_vote'),
              slug: 'create_close_reopen_vote', badge_type: 'create_close_reopen_vote',
              badge_medal_type: 'silver',
              description: I18n.t('badges.default_descs.create_close_reopen_vote'))

Badge.create!(score_needed: 5000, name: I18n.t('badges.badge_types.moderator_tools'),
              slug: 'moderator_tools', badge_type: 'moderator_tools',
              badge_medal_type: 'gold',
              description: I18n.t('badges.default_descs.moderator_tools'))

Badge.create!(name: I18n.t('badges.badge_types.yearling'),
              slug: 'yearling',
              description: I18n.t('badges.default_descs.yearling'),
              badge_type: 'custom',
              badge_medal_type: 'bronze')

Badge.create!(name: I18n.t('badges.badge_types.autobiographer'),
              slug: 'autobiographer',
              description: I18n.t('badges.default_descs.autobiographer'),
              badge_type: 'custom',
              badge_medal_type: 'bronze')

(WRITER_BADGES + SCORE_BADGES).each do |badge|
  Badge.create!(name: I18n.t('badges.badge_types.' + badge[:name]),
                slug: badge[:name],
                description: I18n.t('badges.default_descs.' + badge[:name]),
                badge_type: 'custom',
                badge_medal_type: badge[:type])
end

Badge.create!(name: I18n.t('badges.badge_types.voter'),
              slug: 'voter',
              description: I18n.t('badges.default_descs.voter'),
              badge_type: 'custom',
              badge_medal_type: 'bronze')

b = Badge.create!(score_needed: 700, name: I18n.t('badges.badge_types.seo_profi'),
                  slug: 'seo_profi', badge_type: 'seo_profi',
                  badge_medal_type: 'bronze',
                  description: I18n.t('badges.default_descs.seo_profi'))

users = User.where('(SELECT SUM(value) FROM scores WHERE user_id = users.user_id) >= 700')
users.each do |u|
  b.users << u

  Notification.create!(recipient_id: u.user_id,
                       subject: I18n.t('badges.badge_won',
                                       name: b.name,
                                       mtype: I18n.t('badges.badge_medal_types.' + b.badge_medal_type)),
                       path: '/badges/' + b.slug,
                       oid: b.badge_id,
                       otype: 'badge')
end

# eof
