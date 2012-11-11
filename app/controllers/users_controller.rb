# -*- encoding: utf-8 -*-

class UsersController < ApplicationController
  def index
    @page = params[:p].to_i
    @page = 0 if @page < 0

    if params[:s].blank?
      @users = CfUser.order('username').limit(25).offset(@page * 25)
      @all_users_count = CfUser.count()
    else
      @users = CfUser.where('LOWER(username) LIKE ?', params[:s].strip + '%').order('username').limit(25).offset(@page * 25)
      @all_users_count = CfUser.where('LOWER(username) LIKE ?', params[:s].strip + '%').count()
      @search_term = params[:s]
    end
  end

  def show
    @user = CfUser.find(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def edit
    raise CForum::ForbiddenException.new if current_user.blank? or params[:id].to_i != current_user.user_id

    @user = CfUser.find(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def update
    raise CForum::ForbiddenException.new if current_user.blank? or params[:id].to_i != current_user.user_id

    attrs = params[:cf_user]
    attrs.delete :active
    attrs.delete :admin

    @user = CfUser.find(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()

    saved = false
    CfUser.transaction do
      if @user.update_attributes!(attrs)
        settings = @user.settings
        settings = CfSetting.new if settings.blank?

        settings.user_id = @user.user_id
        settings.options = params[:settings] || {}

        settings.save!

        saved = true
      end
    end

    respond_to do |format|
      if saved
        format.html { redirect_to user_path(@user), notice: 'User has successfully been edited' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

end

# eof