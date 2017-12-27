class AddRelnofollowBadge < ActiveRecord::Migration[5.0]
  include NotifyHelper

  def up
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
  end

  def down
    b = Badge.find_by(slug: 'seo_profi')
    b.destroy if b.present?
  end
end

# eof
