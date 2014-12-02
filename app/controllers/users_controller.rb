# -*- encoding: utf-8 -*-

class UsersController < ApplicationController
  SAVING_SETTINGS  = "saving_settings"
  SAVED_SETTINGS   = "saved_settings"
  SHOWING_SETTINGS = "showing_settings"

  DESTROYING_USER = "destroying_user"
  DESTROYED_USER  = "destroyed_user"

  authorize_action([:edit, :update, :destroy]) do
    not current_user.blank? and (current_user.admin? or current_user.user_id.to_s == params[:id])
  end

  def index
    @limit = conf('pagination_users', 50).to_i

    if params[:s].blank?
      @users = CfUser
    else
      @users = CfUser.where('LOWER(username) LIKE LOWER(?)', '%' + params[:s].strip + '%')
      @search_term = params[:s]
    end

    @users = @users.
             select('*, (SELECT SUM(value) FROM scores WHERE user_id = users.user_id) AS score_sum')

    @users = sort_query(%w(username created_at updated_at score active admin),
                        @users, {score: '(SELECT SUM(value) FROM scores WHERE user_id = users.user_id)'}).
             page(params[:page]).per(@limit)


    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @user = CfUser.find(params[:id])
    @settings = @user.settings || CfSetting.new
    @settings.options ||= {}
    @user_score = CfScore.where(user_id: @user.user_id).sum('value')

    #@messages_count = CfMessage.where(user_id: @user.user_id).count()

    if current_user
      if current_user.admin?
        sql = "SELECT forum_id FROM forums"
      else
        sql = "
        SELECT
            DISTINCT forums.forum_id
          FROM
              forums
            INNER JOIN
              forums_groups_permissions USING(forum_id)
            INNER JOIN
              groups_users USING(group_id)
          WHERE
              (standard_permission = 'read' OR standard_permission = 'write')
            OR
              (
                (
                    permission = 'read'
                  OR
                    permission = 'write'
                  OR
                    permission = 'moderate'
                )
                AND
                  user_id = #{current_user.user_id}
              )
        "
      end
    else
      sql = "SELECT forum_id FROM forums WHERE standard_permission = 'read' OR standard_permission = 'write'"
    end


    @last_messages = CfMessage.
      preload(:owner, :tags, :thread => :forum).
      where("user_id = ? AND deleted = false AND forum_id IN (#{sql})", @user.user_id).
      order('created_at DESC').
      limit(5)

    @tags_cnts = CfMessageTag.
      preload(:tag => :forum).
      joins("INNER JOIN messages USING(message_id)").
      select("tag_id, COUNT(*) AS cnt").
      where("deleted = false AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      group("tag_id").
      order("cnt DESC").
      limit(10)

    @point_msgs = CfMessage.
      preload(:owner, :tags, :thread => :forum).
      where("deleted = false AND upvotes > 0 AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      order('upvotes DESC').
      limit(10)

    @score_msgs = CfScore.
      preload(:vote => {:message => [:thread, :tags]}).
      where(:user_id => @user.user_id).
      limit(10).
      order('created_at DESC')

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.blank? and current_user.username == @user.username)
      flash[:error] = I18n.t('users.confirm_first')
    end
  end

  def edit
    @user = CfUser.find(params[:id])
    @settings = @user.settings || CfSetting.new
    @settings.options ||= {}

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.admin? or current_user.username == @user.username)
      redirect_to user_url(@user), flash: {error: I18n.t('users.confirm_first')}
      return
    end

    notification_center.notify(SHOWING_SETTINGS, @user)

    @messages_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def user_params
    params.require(:cf_user).permit(:username, :email, :password,
                                    :password_confirmation)
  end

  def update
    @user = CfUser.find(params[:id])
    @messages_count = CfMessage.where(user_id: @user.user_id).count()

    @settings = CfSetting.find_by_user_id(@user.user_id)
    @settings = CfSetting.new if @settings.blank?

    @settings.user_id = @user.user_id
    @settings.options = params[:settings] || {}

    saved = false
    CfUser.transaction do
      if @user.update_attributes(user_params)
        notification_center.notify(SAVING_SETTINGS, @user, @settings)
        @settings.save!

        saved = true
      end
    end

    notification_center.notify(SAVED_SETTINGS, @user, @settings)

    respond_to do |format|
      if saved
        sign_in @user, :bypass => true

        format.html { redirect_to edit_user_path(@user), notice: I18n.t('users.updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = CfUser.find(params[:id])

    notification_center.notify(DESTROYING_USER, @user, @settings)
    @user.destroy
    notification_center.notify(DESTROYED_USER, @user, @settings)

    respond_to do |format|
      format.html { redirect_to root_url, notice: I18n.t('users.deleted') }
      format.json { head :no_content }
    end
  end

end

# eof
