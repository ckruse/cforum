# -*- encoding: utf-8 -*-

class Admin::CfBadgesController < ApplicationController
  authorize_controller { authorize_admin }

  before_filter :load_badge

  def index
    @badges = CfBadge.order('UPPER(name) ASC')

    respond_to do |format|
      format.html
      format.json { render json: @badges }
    end
  end

  def edit
  end

  def badge_params
    params.require(:cf_badge).permit(:name, :score_needed, :badge_type,
                                     :badge_medal_type, :slug, :description)
  end

  def update
    if @badge.update_attributes(badge_params)
      redirect_to edit_admin_badge_url(@badge),
                  notice: I18n.t("admin.badges.updated")
    else
      render :edit
    end
  end

  def new
    @badge = CfBadge.new
  end

  def create
    @badge = CfBadge.new(badge_params)

    if @badge.save
      redirect_to edit_admin_badge_url(@badge),
                  notice: I18n.t("admin.badges.created")
    else
      render :new
    end
  end

  def destroy
    @badge.destroy
    redirect_to admin_badges_url, notice: I18n.t("admin.badges.destroyed")
  end

  private
  def load_badge
    @badge = CfBadge.where(slug: params[:id]).first! if params[:id]
  end
end
