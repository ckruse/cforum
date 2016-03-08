# -*- coding: utf-8 -*-

class BadgesController < ApplicationController
  SHOW_BADGE = "show_badge"

  def index
    @limit = conf('pagination').to_i
    @badges = sort_query(%w(badge_medal_type score_needed name no_users),
                         CfBadge.preload(:users),
                         no_users: 'SELECT COUNT(DISTINCT user_id) FROM badges_users WHERE badges_users.badge_id = badges.badge_id')
              .page(params[:page]).per(@limit)


    respond_to do |format|
      format.html
      format.json { render json: @badges }
    end
  end

  def show
    @badge = CfBadge.preload(:users).where(slug: params[:slug]).first!

    notification_center.notify(SHOW_BADGE, @badge)

    respond_to do |format|
      format.html
      format.json { render json: @badge }
    end
  end
end

# eof
