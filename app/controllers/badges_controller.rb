class BadgesController < ApplicationController
  def index
    @limit = conf('pagination', 50).to_i
    @badges = sort_query(%w(badge_medal_type name score_needed no_users),
                         CfBadge.preload(:users),
                         no_users: 'SELECT COUNT(*) FROM badges_users WHERE badges_users.badge_id = badge_id')
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
