# -*- coding: utf-8 -*-

class AddCelebrationBadges < ActiveRecord::Migration
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

    # 100
    CfBadge.create!(name: I18n.t('badges.badge_types.chisel'),
                    slug: "chisel",
                    description: I18n.t('badges.default_descs.chisel'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    # 1000
    CfBadge.create!(name: I18n.t('badges.badge_types.brush'),
                    slug: "brush",
                    description: I18n.t('badges.default_descs.brush'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    # 2500
    CfBadge.create!(name: I18n.t('badges.badge_types.quill'),
                    slug: "quill",
                    description: I18n.t('badges.default_descs.quill'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    # 5000
    CfBadge.create!(name: I18n.t('badges.badge_types.pen'),
                    slug: "pen",
                    description: I18n.t('badges.default_descs.pen'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    # 7500
    CfBadge.create!(name: I18n.t('badges.badge_types.printing_press'),
                    slug: "printing_press",
                    description: I18n.t('badges.default_descs.printing_press'),
                    badge_type: 'custom',
                    badge_medal_type: 'bronze')

    # 10000
    CfBadge.create!(name: I18n.t('badges.badge_types.typewriter'),
                    slug: "typewriter",
                    description: I18n.t('badges.default_descs.typewriter'),
                    badge_type: 'custom',
                    badge_medal_type: 'silver')

    # 20000
    CfBadge.create!(name: I18n.t('badges.badge_types.matrix_printer'),
                    slug: "matrix_printer",
                    description: I18n.t('badges.default_descs.matrix_printer'),
                    badge_type: 'custom',
                    badge_medal_type: 'silver')

    # 30000
    CfBadge.create!(name: I18n.t('badges.badge_types.inkjet_printer'),
                    slug: "inkjet_printer",
                    description: I18n.t('badges.default_descs.inkjet_printer'),
                    badge_type: 'custom',
                    badge_medal_type: 'silver')

    # 40000
    CfBadge.create!(name: I18n.t('badges.badge_types.laser_printer'),
                    slug: "laser_printer",
                    description: I18n.t('badges.default_descs.laser_printer'),
                    badge_type: 'custom',
                    badge_medal_type: 'silver')

    # 50000
    CfBadge.create!(name: I18n.t('badges.badge_types.1000_monkeys'),
                    slug: "1000_monkeys",
                    description: I18n.t('badges.default_descs.1000_monkeys'),
                    badge_type: 'custom',
                    badge_medal_type: 'gold')
  end

  def down
    CfBadge.where(slug: '1000_monkeys').delete_all
    CfBadge.where(slug: 'laser_printer').delete_all
    CfBadge.where(slug: 'inkjet_printer').delete_all
    CfBadge.where(slug: 'matrix_printer').delete_all
    CfBadge.where(slug: 'typewriter').delete_all
    CfBadge.where(slug: 'printing_press').delete_all
    CfBadge.where(slug: 'pen').delete_all
    CfBadge.where(slug: 'quill').delete_all
    CfBadge.where(slug: 'brush').delete_all
    CfBadge.where(slug: 'chisel').delete_all
    CfBadge.where(slug: 'yearling').delete_all

    execute <<-SQL
ALTER TABLE badges
  ALTER COLUMN score_needed SET NOT NULL;
    SQL
  end
end

# eof
