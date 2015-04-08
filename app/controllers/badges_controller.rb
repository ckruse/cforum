# -*- coding: utf-8 -*-

class BadgesController < ApplicationController
  SHOW_BADGE = "show_badge"

  def index
    @limit = conf('pagination').to_i
    @badges = sort_query(%w(score_needed badge_medal_type name no_users),
                         CfBadge.preload(:users),
                         no_users: 'SELECT COUNT(*) FROM badges_users WHERE badges_users.badge_id = badges.badge_id')
              .page(params[:page]).per(@limit)


    respond_to do |format|
      format.html
      format.json { render json: @users }
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
