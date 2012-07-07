# -*- encoding: utf-8 -*-

class Admin::CfUsersController < ApplicationController
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
    @user = CfUser.find_by_username(params[:id])
    @postings_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def edit
    @user = CfUser.find_by_username(params[:id])
  end

  def update
    @user = CfUser.find_by_username(params[:id])

    if @user.update_attributes(params[:cf_user])
      redirect_to edit_admin_cf_user_url(@user), notice: 'User successfully changed' # TODO: localization
    else
      render :edit
    end
  end

  def new
    @user = CfUser.new
  end

  def create
  end

  def destroy
  end
end

# eof