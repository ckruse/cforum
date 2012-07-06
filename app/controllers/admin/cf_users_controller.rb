# -*- encoding: utf-8 -*-

class Admin::CfUsersController < ApplicationController
  def index
    @all_users_count = CfUser.count()

    @page = params[:p].to_i || 0
    @page = 0 if @page < 0

    @users = CfUser.order('username ASC').limit(50).offset(@page * 50).find(:all)
  end

  def show
    @user = CfUser.find_by_username(params[:id])
    @postings_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def edit
  end

  def update
  end

  def new
  end

  def create
  end

  def destroy
  end
end

# eof