# -*- coding: utf-8 -*-

class AddStandardBadges < ActiveRecord::Migration
  def up
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
  end

  def down
    Badge.delete_all
  end
end

# eof
