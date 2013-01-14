# -*- encoding: utf-8 -*-

class Admin::CfUsersController < ApplicationController
  before_filter :authorize!, :load_resource

  include Admin::AuthorizeHelper

  def load_resource
    @user = CfUser.find(params[:id]) if params[:id]
  end

  def index
    @page = params[:p].to_i || 0
    @page = 0 if @page < 0
    @limit = conf('pagination_users', 50).to_i

    @all_users_count = CfUser.count()
    @users = CfUser.order('username ASC').limit(@limit).offset(@page * @limit).find(:all)
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
      redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.created')
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
