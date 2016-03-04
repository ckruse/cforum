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
  end

  def down
    CfBadge.where(slug: 'yearling').delete_all

    execute <<-SQL
ALTER TABLE badges
  ALTER COLUMN score_needed SET NOT NULL;
    SQL
  end
end

# eof
