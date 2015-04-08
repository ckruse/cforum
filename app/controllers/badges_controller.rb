class BadgesController < ApplicationController
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

    respond_to do |format|
      format.html
      format.json { render json: @badge }
    end
  end
end
