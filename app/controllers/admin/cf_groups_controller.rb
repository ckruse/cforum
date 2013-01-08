# -*- encoding: utf-8 -*-

class Admin::CfGroupsController < ApplicationController
  before_filter :authorize!

  include Admin::AuthorizeHelper

  def index
    @groups = CfGroup.order('name ASC').find :all
  end

  def edit
    @group = CfGroup.find params[:id]
  end

  def update
    @group = CfGroup.find params[:id]
    @users = CfUser.find(params[:users])

    saved = false
    CfGroup.transaction do
      raise ActiveRecord::Rollback.new unless @group.update_attributes(params[:cf_group])

      @group.groups_users.clear
      @users.each do |u|
        raise ActiveRecord::Rollback.new unless CfGroupUser.create(group_id: @group.group_id, user_id: u.user_id)
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
  end

  def create
    @group = CfGroup.new(params[:cf_group])
    @users = CfUser.find(params[:users])

    saved = false
    CfGroup.transaction do
      raise ActiveRecord::Rollback.new unless @group.save

      @users.each do |u|
        raise ActiveRecord::Rollback.new unless CfGroupUser.create(group_id: @group.group_id, user_id: u.user_id)
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
