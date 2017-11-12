class CheckYearlingBadgesJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
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
      years = 0 if years.negative?

      years.times do
        give_badge(user, yearling)
      end
    end
  end
end

# eof
