# -*- encoding: utf-8 -*-

class UsersController < ApplicationController
  before_filter :authorize!

  SAVING_SETTINGS = "saving_settings"
  SAVED_SETTINGS  = "saved_settings"

  DESTROYING_USER = "destroying_user"
  DESTROYED_USER  = "destroyed_user"

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

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @user = CfUser.find_by_username!(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.blank? and current_user.username == @user.username)
      flash[:error] = I18n.t('views.confirm_first')
    end
  end

  def edit
    @user = CfUser.find_by_username!(params[:id])

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.admin? or current_user.username == @user.username)
      redirect_to user_url(@user), flash: {error: I18n.t('views.confirm_first')}
      return
    end

    @messages_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def update
    attrs = params[:cf_user]
    attrs.delete :active
    attrs.delete :admin

    @user = CfUser.find_by_username!(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()

    saved = false
    CfUser.transaction do
      if @user.update_attributes(attrs)
        @settings = @user.settings
        @settings = CfSetting.new if @settings.blank?

        @settings.user_id = @user.user_id
        @settings.options = params[:settings] || {}

        notification_center.notify(SAVING_SETTINGS, @user, @settings)
        @settings.save!

        saved = true
      end
    end

    notification_center.notify(SAVED_SETTINGS, @user, @settings)

    respond_to do |format|
      if saved
        format.html { redirect_to edit_user_path(@user), notice: I18n.t('users.updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = CfUser.find_by_username!(params[:id])

    notification_center.notify(DESTROYING_USER, @user, @settings)
    @user.destroy
    notification_center.notify(DESTROYED_USER, @user, @settings)

    respond_to do |format|
      format.html { redirect_to root_url, notice: I18n.t('users.deleted') }
      format.json { head :no_content }
    end
  end

  def authorize!
    return unless %w{edit update destroy}.include?(action_name)
    return if not current_user.blank? and (current_user.admin? or current_user.username == params[:id])

    raise CForum::ForbiddenException.new
  end

end

# eof
