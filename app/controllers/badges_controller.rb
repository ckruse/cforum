class BadgesController < ApplicationController
  def index
    @limit = conf('pagination').to_i
    @badges = sort_query(%w[order badge_medal_type score_needed name no_users],
                         Badge.preload(:users),
                         no_users: 'SELECT COUNT(DISTINCT user_id) FROM badges_users ' \
                                   '  WHERE badges_users.badge_id = badges.badge_id')
                .page(params[:page]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render json: @badges }
    end
  end

  def show
    @badge = Badge.preload(:users).where(slug: params[:slug]).first!

    unnotify_for_badge(@badge)

    respond_to do |format|
      format.html
      format.json { render json: @badge }
    end
  end

  def unnotify_for_badge(badge)
    return if current_user.blank?

    had_one = false
    notifications = Notification.where(otype: 'badge',
                                       oid: badge.badge_id,
                                       recipient_id: current_user.user_id,
                                       is_read: false).all

    notifications.each do |n|
      n.is_read = true
      n.save

      had_one = true
    end

    notifications if had_one
  end
end

# eof
