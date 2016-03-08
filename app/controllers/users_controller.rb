# -*- encoding: utf-8 -*-

class UsersController < ApplicationController
  SAVING_SETTINGS  = "saving_settings"
  SAVED_SETTINGS   = "saved_settings"
  SHOWING_SETTINGS = "showing_settings"

  DESTROYING_USER = "destroying_user"
  DESTROYED_USER  = "destroyed_user"

  include HighlightHelper

  authorize_action([:edit, :update, :confirm_destroy, :destroy]) do
    not current_user.blank? and (current_user.admin? or current_user.user_id.to_s == params[:id])
  end

  def index
    @limit = conf('pagination_users').to_i

    if not params[:s].blank?
      @users = CfUser.where('LOWER(username) LIKE LOWER(?)', '%' + params[:s].strip + '%')
      @search_term = params[:s]
    elsif not params[:nick].blank?
      @users = CfUser.where('LOWER(username) LIKE LOWER(?)', params[:nick].strip + '%')
      params[:sort] = 'num_msgs'
      params[:dir] = 'desc'
    else
      @users = CfUser
    end

    num_msgs = "(SELECT COUNT(*) FROM messages WHERE user_id = users.user_id AND created_at >= NOW() - INTERVAL '30 days')"
    score_sum = "COALESCE((SELECT SUM(value) FROM scores WHERE user_id = users.user_id), 0)"

    @users = @users.
             select("*, #{score_sum} AS score_sum, #{num_msgs} AS num_msgs")
    @users = sort_query(%w(username created_at updated_at score active admin num_msgs),
                        @users, {score: score_sum,
                                 admin: 'COALESCE(admin, false)',
                                 num_msgs: num_msgs}).
             order('username ASC').
             page(params[:page]).per(@limit)


    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @user = CfUser.preload(badges_users: :badge).find(params[:id])
    @settings = @user.settings || CfSetting.new
    @settings.options ||= {}
    @user_score = CfScore.where(user_id: @user.user_id).sum('value')

    @messages_count = CfMessage.where(user_id: @user.user_id, deleted: false).count()

    sql = CfForum.visible_sql(current_user)

    @last_messages = CfMessage.
      preload(:owner, :tags, votes: :voters, thread: :forum).
      where("user_id = ? AND deleted = false AND forum_id IN (#{sql})", @user.user_id).
      order('created_at DESC').
      limit(5)

    @tags_cnts = CfMessageTag.
      preload(tag: :forum).
      joins("INNER JOIN messages USING(message_id)").
      select("tag_id, COUNT(*) AS cnt").
      where("deleted = false AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      group("tag_id").
      order("cnt DESC").
      limit(10)

    @point_msgs = CfMessage.
      preload(:owner, :tags, votes: :voters, thread: :forum).
      where("deleted = false AND upvotes > 0 AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      order('upvotes DESC').
      limit(10)

    scored_msgs = CfScore.
      preload(message: [:owner, :tags, {thread: :forum, votes: :voters}], vote: {message: [:owner, :tags, {thread: :forum, votes: :voters}]}).
      joins("LEFT JOIN messages m1 USING(message_id)
             LEFT JOIN votes USING(vote_id)
             LEFT JOIN messages m2 ON votes.message_id = m2.message_id").
      where(user_id: @user.user_id).
      where("m1.message_id IS NULL OR m1.forum_id IN (#{sql})").
      where("m2.message_id IS NULL OR m2.forum_id IN (#{sql})").
      where("m1.message_id IS NULL OR m1.deleted = false").
      where("m2.message_id IS NULL OR m2.deleted = false").
      limit(10).
      order('created_at DESC')

    if current_user.try(:user_id) != @user.user_id
      scored_msgs = scored_msgs.where("m2.user_id = ?", @user.user_id)
    end

    @score_msgs = {}
    fake_id = 0
    scored_msgs.each do |score|
      m = score.vote ? score.vote.message : score.message

      id = if m.blank?
             fake_id += 1
             "fake-#{fake_id}"
           else
             m.message_id
           end

      @score_msgs[id] ||= []
      @score_msgs[id] << score
    end

    @score_msgs = @score_msgs.values.sort { |a,b|
      b.last.created_at <=> a.last.created_at
    }

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.blank? and current_user.username == @user.username)
      flash[:error] = I18n.t('users.confirm_first')
    end

    @badges = @user.unique_badges
  end

  def edit
    @user = CfUser.find(params[:id])
    @settings = @user.settings || CfSetting.new
    @settings.options ||= {}

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.admin? or current_user.username == @user.username)
      redirect_to user_url(@user), flash: {error: I18n.t('users.confirm_first')}
      return
    end

    highlight_showing_settings(@user)

    notification_center.notify(SHOWING_SETTINGS, @user)

    @messages_count = CfMessage.where(user_id: @user.user_id).count()
  end

  def user_params
    params.require(:cf_user).permit(:username, :email, :password,
                                    :password_confirmation, :avatar)
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

        highlight_saving_settings(@settings)

        notification_center.notify(SAVING_SETTINGS, @user, @settings)
        @settings.save!

        check_for_autobiographer(@user, @settings)

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

  def confirm_destroy
    @user = CfUser.find(params[:id])
  end

  def destroy
    @user = CfUser.find(params[:id])

    notification_center.notify(DESTROYING_USER, @user, @settings)
    @user.destroy
    audit(@user, 'destroy', nil)
    notification_center.notify(DESTROYED_USER, @user, @settings)

    respond_to do |format|
      format.html { redirect_to root_url, notice: I18n.t('users.deleted') }
      format.json { head :no_content }
    end
  end

  def show_scores
    @user = CfUser.find(params[:id])

    sql = CfForum.visible_sql(current_user)

    @scored_msgs = CfScore.
                   preload(message: [:owner, :tags,
                                     {thread: :forum, votes: :voters}],
                           vote: {message: [:owner, :tags,
                                            {thread: :forum, votes: :voters}]}).
      joins("LEFT JOIN messages m1 USING(message_id)
             LEFT JOIN votes USING(vote_id)
             LEFT JOIN messages m2 ON votes.message_id = m2.message_id").
      where(user_id: @user.user_id).
      where("m1.message_id IS NULL OR m1.forum_id IN (#{sql})").
      where("m2.message_id IS NULL OR m2.forum_id IN (#{sql})").
      where("m1.message_id IS NULL OR m1.deleted = false").
      where("m2.message_id IS NULL OR m2.deleted = false").
      order('created_at DESC').
      page(params[:page]).
      per(conf('pagination'))

    if current_user.try(:user_id) != @user.user_id
      @scored_msgs = @scored_msgs.where("m2.user_id = ?", @user.user_id)
    end

  end

  def show_messages
    @user = CfUser.find(params[:id])

    sql = CfForum.visible_sql(current_user)

    @messages = CfMessage.
                preload(:owner, :tags, votes: :voters, thread: :forum).
                where("user_id = ? AND deleted = false AND forum_id IN (#{sql})", @user.user_id).
                order('created_at DESC').
                page(params[:page]).
                per(conf('pagination'))
  end

  private

  def check_for_autobiographer(user, settings)
    return if settings.blank?

    b = user.badges.find { |badge| badge.slug == 'autobiographer' }
    return if not b.blank?

    if not settings.options['description'].blank? and
      not settings.options['url'].blank? and
      (not settings.options['email'].blank? or
       not settings.options['jabber_id'].blank? or
       not settings.options['twitter_handle'].blank? or
       not settings.options['flattr'].blank?)
      badge = CfBadge.where(slug: 'autobiographer').first!

      user.badges_users.create!(badge_id: badge.badge_id,
                                created_at: Time.zone.now,
                                updated_at: Time.zone.now)

      audit(user, 'badge-gained', nil)
      notify_user(user: user,
                  hook: '',
                  subject: I18n.t('badges.badge_won',
                                  name: badge.name,
                                  mtype: I18n.t("badges.badge_medal_types." + badge.badge_medal_type)),
                  path: cf_badge_path(badge),
                  oid: badge.badge_id,
                  otype: 'badge')

    end
  end

end

# eof
