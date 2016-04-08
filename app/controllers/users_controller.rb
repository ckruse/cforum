# -*- encoding: utf-8 -*-

class UsersController < ApplicationController
  include HighlightHelper

  authorize_action([:edit, :update, :confirm_destroy, :destroy]) do
    not current_user.blank? and (current_user.admin? or current_user.user_id.to_s == params[:id])
  end

  def index
    @limit = conf('pagination_users').to_i

    if not params[:s].blank?
      @users = User.where('LOWER(username) LIKE LOWER(?)', '%' + params[:s].strip + '%')
      @search_term = params[:s]
    elsif not params[:nick].blank?
      @users = User.where('LOWER(username) LIKE LOWER(?)', params[:nick].strip + '%')
      params[:sort] = 'num_msgs'
      params[:dir] = 'desc'
    elsif not params[:exact].blank?
      @users = User.where('LOWER(username) = LOWER(?)', params[:exact].strip)
    else
      @users = User
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
    @user = User.preload(badge_users: :badge).find(params[:id])
    @settings = @user.settings || Setting.new
    @settings.options ||= {}
    @user_score = Score.where(user_id: @user.user_id).sum('value')

    @messages_count = Message.where(user_id: @user.user_id, deleted: false).count()

    sql = Forum.visible_sql(current_user)

    @last_messages = Message.
      preload(:owner, :tags, votes: :voters, thread: :forum).
      where("user_id = ? AND deleted = false AND forum_id IN (#{sql})", @user.user_id).
      order('created_at DESC').
      limit(5)

    @tags_cnts = MessageTag.
      preload(tag: :forum).
      joins("INNER JOIN messages USING(message_id)").
      select("tag_id, COUNT(*) AS cnt").
      where("deleted = false AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      group("tag_id").
      order("cnt DESC").
      limit(10)

    @point_msgs = Message.
      preload(:owner, :tags, votes: :voters, thread: :forum).
      where("deleted = false AND upvotes > 0 AND user_id = ? AND forum_id IN (#{sql})", @user.user_id).
      order('upvotes DESC').
      limit(10)

    scored_msgs = Score.
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
    @user = User.find(params[:id])
    @settings = @user.settings || Setting.new
    @settings.options ||= {}

    if (@user.confirmed_at.blank? or not @user.unconfirmed_email.blank?) and (not current_user.admin? or current_user.username == @user.username)
      redirect_to user_url(@user), flash: {error: I18n.t('users.confirm_first')}
      return
    end

    highlight_showing_settings(@user)

    @messages_count = Message.where(user_id: @user.user_id).count()
  end

  def user_params
    params.require(:user).permit(:username, :email, :password,
                                 :password_confirmation, :avatar)
  end

  def update
    @user = User.find(params[:id])
    @messages_count = Message.where(user_id: @user.user_id).count()

    @settings = Setting.find_by_user_id(@user.user_id)
    @settings = Setting.new if @settings.blank?

    @settings.user_id = @user.user_id
    @settings.options = params[:settings] || {}

    saved = false
    User.transaction do
      if @user.update_attributes(user_params)

        highlight_saving_settings(@settings)

        @settings.save!

        check_for_autobiographer(@user, @settings)

        saved = true
      end
    end

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
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])

    @user.destroy
    audit(@user, 'destroy', nil)

    respond_to do |format|
      format.html { redirect_to root_url, notice: I18n.t('users.deleted') }
      format.json { head :no_content }
    end
  end

  def show_scores
    @user = User.find(params[:id])

    sql = Forum.visible_sql(current_user)

    @scored_msgs = Score.
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
    @user = User.find(params[:id])

    sql = Forum.visible_sql(current_user)

    @messages = Message.
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
      badge = Badge.where(slug: 'autobiographer').first!

      user.badge_users.create!(badge_id: badge.badge_id,
                               created_at: Time.zone.now,
                               updated_at: Time.zone.now)

      audit(user, 'badge-gained', nil)
      notify_user(user: user,
                  hook: '',
                  subject: I18n.t('badges.badge_won',
                                  name: badge.name,
                                  mtype: I18n.t("badges.badge_medal_types." + badge.badge_medal_type)),
                  path: badge_path(badge),
                  oid: badge.badge_id,
                  otype: 'badge')

    end
  end

end

# eof
