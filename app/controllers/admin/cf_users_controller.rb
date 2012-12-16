# -*- encoding: utf-8 -*-

class Admin::CfUsersController < ApplicationController
  before_filter :authorize!, :load_resource

  include Admin::AuthorizeHelper

  def load_resource
    @user = CfUser.find_by_username(params[:id]) if params[:id]
  end

  def index
    @page = params[:p].to_i || 0
    @page = 0 if @page < 0

    unless params[:s].blank?
      args = ["UPPER(username) LIKE UPPER(?) OR UPPER(email) LIKE UPPER(?)", params[:s].to_s + '%', params[:s].to_s + '%']
      @all_users_count = CfUser.where(args).count()
      @users = CfUser.where(args).order('username ASC').limit(50).offset(@page * 50)
    else
      @all_users_count = CfUser.count()
      @users = CfUser.order('username ASC').limit(50).offset(@page * 50).find(:all)
    end
  end

  def show
    @postings_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:cf_user])
      redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.updated')
    else
      render :edit
    end
  end

  def new
    @user = CfUser.new
  end

  def create
    @user = CfUser.new(params[:cf_user])

    if @user.save
      redirect_to admin_user_url(@user), notice: I18n.t('admin.users.created')
    else
      render :new
    end
  end

  def destroy
    @user.destroy

    redirect_to admin_users_url, notice: I18n.t('admin.users.deleted')
  end
end

# eof