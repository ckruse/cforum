class Admin::BadgeGroupsController < ApplicationController
  authorize_controller { authorize_admin }

  before_action :set_badge_group, only: %i[edit update destroy]
  before_action :load_badges, only: %i[edit update new create]

  # GET /badge_groups
  def index
    @badge_groups = BadgeGroup.all
  end

  # GET /badge_groups/new
  def new
    @badge_group = BadgeGroup.new
  end

  # GET /badge_groups/1/edit
  def edit; end

  # POST /badge_groups
  def create
    @badge_group = BadgeGroup.new(badge_group_params)

    if params[:badges].present?
      badge_ids = @badges.map(&:badge_id)
      params[:badges].each do |badge|
        @badge_group.badge_badge_groups.build(badge_id: badge.to_i) if badge.to_i.in?(badge_ids)
      end
    end

    if @badge_group.save
      redirect_to admin_badge_groups_url, notice: t('admin.badge_groups.created')
    else
      render :new
    end
  end

  # PATCH/PUT /badge_groups/1
  def update
    saved = false

    BadgeGroup.transaction do
      if @badge_group.update(badge_group_params)
        @badge_group.badge_badge_groups.clear

        if params[:badges].present?
          badge_ids = @badges.map(&:badge_id)
          params[:badges].each do |badge|
            @badge_group.badge_badge_groups.create!(badge_id: badge.to_i) if badge.to_i.in?(badge_ids)
          end
        end

        saved = true
      end
    end

    if saved
      redirect_to admin_badge_groups_url, notice: t('admin.badge_groups.updated')
    else
      render :edit
    end
  end

  # DELETE /badge_groups/1
  def destroy
    @badge_group.destroy
    redirect_to admin_badge_groups_url, notice: t('admin.badge_groups.destroyed')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_badge_group
    @badge_group = BadgeGroup.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def badge_group_params
    params.require(:badge_group).permit(:name)
  end

  def load_badges
    @badges = Badge.order(:order).all
  end
end
