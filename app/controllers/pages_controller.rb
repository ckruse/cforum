class PagesController < ApplicationController
  def help
    @moderators = User
                    .where('admin = true OR' \
                           '  user_id IN (SELECT user_id FROM groups_users WHERE group_id IN ' \
                           '    (SELECT group_id FROM forums_groups_permissions WHERE permission = ?)) OR' \
                           '  user_id IN (SELECT user_id FROM badges_users INNER JOIN badges USING(badge_id)' \
                           '              WHERE badge_type = ?)',
                           ForumGroupPermission::MODERATE, Badge::MODERATOR_TOOLS)
                    .order(:username)

    @badge_groups = BadgeGroup
                      .preload(:badges)
                      .order(:name)
                      .all

    @cites = Cite
               .select("date_trunc('month', created_at) AS created_at, COUNT(*) AS cnt")
               .where("created_at >= NOW() - INTERVAL '12 months'")
               .group("date_trunc('month', created_at)")
               .order("date_trunc('month', created_at)")
               .all
  end
end

# eof
