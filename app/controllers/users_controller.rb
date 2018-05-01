class UsersController < ApplicationController
  include HighlightHelper

  authorize_action(%i[edit update confirm_destroy destroy]) do
    current_user.present? && (current_user.admin? || (current_user.user_id.to_s == params[:id]))
  end

  authorize_action(%i[show_votes edit_password update_password]) do
    current_user.present? && (current_user.user_id.to_s == params[:id])
  end

  def index
    @limit = conf('pagination_users').to_i

    if params[:s].present?
      @users = User.where('LOWER(username) LIKE LOWER(?)', '%' + params[:s].strip + '%')
      @search_term = params[:s]
    elsif params[:nick].present?
      @users = User.where('LOWER(username) LIKE LOWER(?)', params[:nick].strip + '%')
      params[:sort] = 'activity'
      params[:dir] = 'desc'
    elsif params[:exact].present?
      @users = User.where('LOWER(username) = LOWER(?)', params[:exact].strip)
    else
      @users = User
    end

    @users = sort_query(%w[username created_at updated_at score active admin activity],
                        @users, admin: 'COALESCE(admin, false)')
               .order('username ASC')
               .page(params[:page]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @user = User.preload(badge_users: :badge).find(params[:id])
    @settings = @user.settings || Setting.new
    @settings.options ||= {}

    @messages_by_months = Message
                            .select("DATE_TRUNC('month', created_at) created_at, COUNt(*) cnt")
                            .where(user_id: @user.user_id,
                                   deleted: false)
                            .order("DATE_TRUNC('month', created_at)")
                            .group("DATE_TRUNC('month', created_at)")
                            .all

    @messages_count = Message.where(user_id: @user.user_id, deleted: false).count

    fids = Forum.visible_forums(current_user).select(:forum_id)

    @last_messages = Message
                       .preload(:owner, :tags, votes: :voters, thread: :forum)
                       .where('user_id = ? AND deleted = false AND forum_id IN (?)', @user.user_id, fids)
                       .order('created_at DESC')
                       .limit(5)

    @tags_cnts = MessageTag
                   .preload(tag: :forum)
                   .joins('INNER JOIN messages USING(message_id)')
                   .select('tag_id, COUNT(*) AS cnt')
                   .where('deleted = false AND user_id = ? AND forum_id IN (?)', @user.user_id, fids)
                   .group('tag_id')
                   .order('cnt DESC')
                   .limit(10)

    @point_msgs = Message
                    .preload(:owner, :tags, votes: :voters, thread: :forum)
                    .where('deleted = false AND upvotes > 0 AND user_id = ? AND forum_id IN (?)',
                           @user.user_id, fids)
                    .order('upvotes - downvotes DESC', 'created_at DESC')
                    .limit(10)

    scored_msgs = Score
                    .preload(message: [:owner, :tags,
                                       { thread: :forum, votes: :voters }],
                             vote: { message: [:owner, :tags,
                                               { thread: :forum, votes: :voters }] })
                    .joins("LEFT JOIN messages m1 USING(message_id)
             LEFT JOIN votes USING(vote_id)
             LEFT JOIN messages m2 ON votes.message_id = m2.message_id")
                    .where(user_id: @user.user_id)
                    .where('m1.message_id IS NULL OR m1.forum_id IN (?)', fids)
                    .where('m2.message_id IS NULL OR m2.forum_id IN (?)', fids)
                    .where('m1.message_id IS NULL OR m1.deleted = false')
                    .where('m2.message_id IS NULL OR m2.deleted = false')
                    .limit(10)
                    .order('created_at DESC')

    if current_user.try(:user_id) != @user.user_id
      scored_msgs = scored_msgs.where('m2.user_id = ?', @user.user_id)
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

    @score_msgs = @score_msgs.values.sort do |a, b|
      b.last.created_at <=> a.last.created_at
    end

    if (@user.confirmed_at.blank? || @user.unconfirmed_email.present?) &&
       (current_user.present? && (current_user.username == @user.username))
      flash[:error] = I18n.t('users.confirm_first')
    end

    @badges = @user.unique_badges
  end

  def edit
    @user = User.find(params[:id])
    @settings = @user.settings || Setting.new
    @settings.options ||= {}

    if (@user.confirmed_at.blank? || @user.unconfirmed_email.present?) &&
       (!current_user.admin? || (current_user.username == @user.username))
      redirect_to user_url(@user), flash: { error: I18n.t('users.confirm_first') }
      return
    end

    highlight_showing_settings(@user)

    @messages_count = Message.where(user_id: @user.user_id).count
  end

  def update
    @user = User.find(params[:id])
    @messages_count = Message.where(user_id: @user.user_id).count

    @settings = Setting.where(user_id: @user.user_id).first
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

    fids = Forum.visible_forums(current_user).select(:forum_id)

    @scored_msgs = Score
                     .preload(message: [:owner, :tags,
                                        { thread: :forum, votes: :voters }],
                              vote: { message: [:owner, :tags,
                                                { thread: :forum, votes: :voters }] })
                     .joins("LEFT JOIN messages m1 USING(message_id)
             LEFT JOIN votes USING(vote_id)
             LEFT JOIN messages m2 ON votes.message_id = m2.message_id")
                     .where(user_id: @user.user_id)
                     .where('m1.message_id IS NULL OR m1.forum_id IN (?)', fids)
                     .where('m2.message_id IS NULL OR m2.forum_id IN (?)', fids)
                     .where('m1.message_id IS NULL OR m1.deleted = false')
                     .where('m2.message_id IS NULL OR m2.deleted = false')
                     .order('created_at DESC')
                     .page(params[:page])
                     .per(conf('pagination'))

    @scored_msgs = @scored_msgs.where('m2.user_id = ?', @user.user_id) if current_user.try(:user_id) != @user.user_id
  end

  def show_votes
    @user = User.find(params[:id])
    fids = Forum.visible_forums(current_user).select(:forum_id)

    @votes = Vote
               .joins(:message)
               .preload(:score, message: [:owner, :tags,
                                          { thread: :forum, votes: :voters }])
               .where(user_id: @user.user_id)
               .where('forum_id IN (?) AND deleted = false', fids)
               .order('created_at DESC')
               .page(params[:page])
               .per(conf('pagination'))
  end

  def show_messages
    @user = User.find(params[:id])

    fids = Forum.visible_forums(current_user).select(:forum_id)

    @messages = Message
                  .preload(:owner, :tags, votes: :voters, thread: :forum)
                  .where('user_id = ? AND deleted = false AND forum_id IN (?)', @user.user_id, fids)
                  .order('created_at DESC')
                  .page(params[:page])
                  .per(conf('pagination'))
  end

  def edit_password
    @user = User.find(params[:id])
  end

  def update_password
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(user_password_params)
        bypass_sign_in @user

        format.html { redirect_to user_path(@user), notice: I18n.t('users.password_changed') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit_password' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :avatar)
  end

  def user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def check_for_autobiographer(user, settings)
    return if settings.blank?

    b = user.badges.find { |badge| badge.slug == 'autobiographer' }
    return if b.present?

    if settings.options['description'].present? &&
       settings.options['url'].present? &&
       (settings.options['email'].present? ||
        settings.options['jabber_id'].present? ||
        settings.options['twitter_handle'].present?)
      badge = Badge.where(slug: 'autobiographer').first!

      user.badge_users.create!(badge_id: badge.badge_id,
                               created_at: Time.zone.now,
                               updated_at: Time.zone.now)

      audit(user, 'badge-gained', nil)
      notify_user(user: user,
                  hook: '',
                  subject: I18n.t('badges.badge_won',
                                  name: badge.name,
                                  mtype: I18n.t('badges.badge_medal_types.' + badge.badge_medal_type)),
                  path: badge_path(badge),
                  oid: badge.badge_id,
                  otype: 'badge')

    end
  end
end

# eof
