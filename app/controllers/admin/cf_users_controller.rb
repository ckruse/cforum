# -*- encoding: utf-8 -*-

class Admin::CfUsersController < ApplicationController
  authorize_controller { authorize_admin }

  before_filter :load_resource

  def load_resource
    @user = CfUser.find(params[:id]) if params[:id]
  end

  def index
    @limit = conf('pagination_users').to_i

    if params[:s].blank?
      @users = CfUser
    else
      @users = CfUser.where('LOWER(username) LIKE ?', '%' + params[:s].strip + '%')
      @search_term = params[:s]
    end

    @users = sort_query(%w(username email admin active created_at updated_at),
                        @users).page(params[:page]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def edit
  end

  def user_params
    params.require(:cf_user).permit(:username, :email, :password, :active, :admin)
  end

  def update
    if @user.update_attributes(user_params)
      redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.updated')
    else
      render :edit
    end
  end

  def new
    @user = CfUser.new
  end

  def create
    @user = CfUser.new(user_params)

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
