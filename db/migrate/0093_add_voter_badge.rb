class AddVoterBadge < ActiveRecord::Migration
  def up
    Badge.create!(name: I18n.t('badges.badge_types.voter'),
                  slug: 'voter',
                  description: I18n.t('badges.default_descs.voter'),
                  badge_type: 'custom',
                  badge_medal_type: 'bronze')
  end

  def down
    Badge.where(slug: 'voter').delete_all
  end
end

# eof
