# -*- encoding: utf-8 -*-

class Admin::CfGroupsController < ApplicationController
  before_filter :authorize!

  include Admin::AuthorizeHelper

  def index
    @limit = conf('pagination', 50).to_i
    @limit = 50 if @limit <= 0

    @groups = CfGroup.page(params[:p]).per(@limit).order('UPPER(name) ASC')
  end

  def edit
    @group = CfGroup.find params[:id]
    @forums_groups_permissions = @group.forums_groups_permissions
    @users = @group.users
    @forums = CfForum.all
  end

  def group_params
    params.require(:cf_group).permit(:name)
  end

  def update
    @group = CfGroup.find params[:id]
    @forums = CfForum.all

    @users = []
    @users = CfUser.find(params[:users]) unless params[:users].blank?

    @forums_groups_permissions = []
    if not params[:forums].blank? and not params[:permissions].blank?
      (params[:forums].length - 1).times do |i|
        next if params[:forums][i].blank? or params[:permissions][i].blank?

        @forums_groups_permissions << [params[:forums][i],params[:permissions][i]]
      end
    end

    saved = false
    CfGroup.transaction do
      raise ActiveRecord::Rollback.new unless @group.update_attributes(group_params)

      @group.groups_users.clear
      @users.each do |u|
        raise ActiveRecord::Rollback.new unless CfGroupUser.create(group_id: @group.group_id, user_id: u.user_id)
      end

      @group.forums_groups_permissions.clear
      @forums_groups_permissions.each do |fgp|
        @group.forums_groups_permissions.create!(forum_id: fgp[0],
                                                   permission: fgp[1])
      end

      saved = true
    end

    if saved
      redirect_to edit_admin_group_url(@group), notice: I18n.t("admin.groups.updated")
    else
      render :edit
    end
  end

  def new
    @group = CfGroup.new
    @forums = CfForum.all
    @forums_groups_permissions = []
    @users = []
  end

  def create
    @group = CfGroup.new(group_params)
    @forums = CfForum.all

    @users = []
    @users = CfUser.find(params[:users]) unless params[:users].blank?

    @forums_groups_permissions = []
    if not params[:forums].blank? and not params[:permissions].blank?
      (params[:forums].length - 1).times do |i|
        next if params[:forums][i].blank? or params[:permissions][i].blank?

        @forums_groups_permissions << CfForumGroupPermission.new(
          forum_id: params[:forums][i],
          permission: params[:permissions][i]
        )
      end
    end

    saved = false
    CfGroup.transaction do
      raise ActiveRecord::Rollback.new unless @group.save

      @users.each do |u|
        raise ActiveRecord::Rollback.new unless CfGroupUser.create(group_id: @group.group_id, user_id: u.user_id)

        @forums_groups_permissions.each do |fgp|
          fgp.group_id = @group.group_id
          fgp.save!
        end
      end

      saved = true
    end

    if saved
      redirect_to edit_admin_group_url(@group), notice: I18n.t("admin.groups.created")
    else
      render :new
    end
  end

  def destroy
    @group = CfGroup.find params[:id]
    @group.destroy

    redirect_to admin_groups_url, notice: I18n.t("admin.groups.deleted")
  end

end

# eof
