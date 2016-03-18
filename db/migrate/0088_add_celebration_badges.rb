# -*- coding: utf-8 -*-

class AddCelebrationBadges < ActiveRecord::Migration
  WRITER_BADGES = [
    { messages: 100, name: 'chisel', type: 'bronze' },
    { messages: 1000, name: 'brush', type: 'bronze' },
    { messages: 2500, name: 'quill', type: 'bronze' },
    { messages: 5000, name: 'pen', type: 'bronze' },
    { messages: 7500, name: 'printing_press', type: 'bronze' },
    { messages: 10000, name: 'typewriter', type: 'silver' },
    { messages: 20000, name: 'matrix_printer', type: 'silver' },
    { messages: 30000, name: 'inkjet_printer', type: 'silver' },
    { messages: 40000, name: 'laser_printer', type: 'silver' },
    { messages: 50000, name: '1000_monkeys', type: 'gold' }
  ]

  SCORE_BADGES = [
    {name: 'donee', type: 'bronze'},
    {name: 'nice_answer', type: 'bronze'},
    {name: 'good_answer', type: 'silver'},
    {name: 'great_answer', type: 'silver'},
    {name: 'superb_answer', type: 'gold'},
    {name: 'controverse', type: 'bronze'},
    {name: 'enthusiast', type: 'bronze'},
    {name: 'critic', type: 'bronze'},
    {name: 'teacher', type: 'bronze'}
  ]

  def up
    execute <<-SQL
ALTER TABLE badges
  ALTER COLUMN score_needed DROP NOT NULL;
    SQL

    CfBadge.create!(name: I18n.t('badges.badge_types.yearling'),
                    slug: "yearling",
                    description: I18n.t('badges.default_descs.yearling'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    CfBadge.create!(name: I18n.t('badges.badge_types.autobiographer'),
                    slug: "autobiographer",
                    description: I18n.t('badges.default_descs.autobiographer'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')


    (WRITER_BADGES + SCORE_BADGES).each do |badge|
      CfBadge.create!(name: I18n.t('badges.badge_types.' + badge[:name]),
                      slug: badge[:name],
                      description: I18n.t('badges.default_descs.' + badge[:name]),
                      badge_type: 'custom',
                      badge_medal_type: badge[:type])
    end

  end

  def down
    (WRITER_BADGES + SCORE_BADGES).each do |badge|
      CfBadge.where(slug: badge[:name]).delete_all
    end

    CfBadge.where(slug: 'autobiographer').delete_all
    CfBadge.where(slug: 'yearling').delete_all

    execute <<-SQL
ALTER TABLE badges
  ALTER COLUMN score_needed SET NOT NULL;
    SQL
  end
end

# eof