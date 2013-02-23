# -*- encoding: utf-8 -*-

class CfThreadsController < ApplicationController
  before_filter :authorize!

  include AuthorizeForum
  include TagsHelper

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_NEW_THREAD  = "show_new_thread"
  NEW_THREAD       = "new_thread"
  NEW_THREAD_SAVED = "new_thread_saved"

  def index
    forum  = current_forum
    @page  = params[:p].to_i
    @limit = uconf('pagination', 50).to_i
    @page  = 0 if @page < 0

    @limit = 50 if @limit <= 0

    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false if conf('use_archive') == 'yes'
    conditions[:messages] = {deleted: false} unless @view_all

    # the „no forum” case is much more complex; we have to do it partly manually
    # to avoid DISTINCT
    sql = "SELECT thread_id FROM threads WHERE "
    crits = []

    if forum
      crits << "forum_id = " + forum.forum_id.to_s
      crits << "deleted = false" unless @view_all
    else
      if current_user and current_user.admin?
        crits = []

      else
        crits << "forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = " + current_user.user_id.to_s + ")" if current_user
        crits << "forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
          CfForumGroupPermission::ACCESS_READ + "','" +
          CfForumGroupPermission::ACCESS_WRITE +
            (current_user ? ("', '" +
                             CfForumGroupPermission::ACCESS_KNOWN_WRITE + "','" +
                             CfForumGroupPermission::ACCESS_KNOWN_READ) : ""
            ) +
          "'))"

        crits = ["(" + crits.join(" OR ") + ")"]
      end

      unless @view_all
        crits << 'threads.deleted = false' #"EXISTS(SELECT message_id FROM messages WHERE thread_id = threads.thread_id AND deleted = false)"
      end
    end
    sql << crits.join(" AND ")
    sql << " ORDER BY threads.sticky DESC, threads.created_at DESC LIMIT #{@limit} OFFSET #{@limit * @page}"

    result = CfThread.connection.execute(sql)

    ids = []
    result.each do |row|
      ids << row['thread_id'].to_i
    end

    @threads = CfThread.
      preload(:forum, :messages => [:owner, :tags]).
      includes(:messages => :owner).
      where(conditions).
      where(thread_id: ids).
      order('threads.sticky DESC, threads.created_at DESC').
      all

    if forum
      rslt = CfForum.connection.execute("SELECT counter_table_get_count('threads', " +
        current_forum.forum_id.to_s +
        ") AS cnt")
    else
      rslt = CfForum.connection.execute("SELECT SUM(difference) AS cnt FROM counter_table WHERE table_name = 'threads'")
    end

    @all_threads_count = rslt[0]['cnt'].to_i

    ret = notification_center.notify(SHOW_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.rss
        format.atom
      end
    end
  end

  # TODO: implement editing
  # def edit
  #   @id = CfThread.make_id(params)
  #   @thread = CfThread.includes(:messages).find_by_slug!(@id)
  # end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new
    @tags = []

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    now = Time.now
    invalid = false

    @forum = current_forum

    @thread  = CfThread.new()
    @message = CfMessage.new(params[:cf_thread][:message])
    @thread.message  =  @message
    @thread.slug     = CfThread.gen_id(@thread)

    @thread.forum_id    = @forum.forum_id
    @message.forum_id   = @forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.content    = CfMessage.to_internal(@message.content)

    @message.created_at = DateTime.now
    @message.updated_at = DateTime.now

    if current_user
      @message.author   = current_user.username
    else
      unless CfUser.where('LOWER(username) = LOWER(?)', @message.author.strip).first.blank?
        flash[:error] = I18n.t('errors.name_taken')
        invalid = true
      end
    end

    @tags    = parse_tags
    @preview = true if params[:preview]
    retvals  = notification_center.notify(NEW_THREAD, @thread, @message, @tags)

    unless current_user
      cookies[:cforum_user] = {value: request.uuid, expires: 1.year.from_now} if cookies[:cforum_user].blank?
      @message.uuid = cookies[:cforum_user]

      cookies[:cforum_author]   = {value: @message.author, expires: 1.year.from_now}
      cookies[:cforum_email]    = {value: @message.email, expires: 1.year.from_now}
      cookies[:cforum_homepage] = {value: @message.homepage, expires: 1.year.from_now}
    end

    saved = false
    if not invalid and not @preview and not retvals.include?(false)
      CfThread.transaction do
        num = 1

        begin
          CfThread.transaction do
            @thread.save!
          end
        rescue ActiveRecord::RecordInvalid => e
          if @thread.errors.keys == [:slug]
            @thread.slug = CfThread.gen_id(@thread, num)
            num += 1
            retry
          end

          raise ActiveRecord::Rollback
        end

        @message.thread_id = @thread.thread_id
        raise ActiveRecord::Rollback unless @message.save

        save_tags(@message, @tags)

        @thread.messages << @message

        saved = true
      end
    end

    respond_to do |format|
      if not @preview and saved
        notification_center.notify(NEW_THREAD_SAVED, @thread, @message)

        format.html { redirect_to cf_message_url(@thread, @message), notice: I18n.t("threads.created") }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  # TODO: implement
  # def destroy
  # end

  def moving
    @id     = CfThread.make_id(params)
    @thread = CfThread.includes(:forum).find_by_slug!(@id)

    if current_user.admin
      @forums = CfForum.order('name ASC').find :all
    else
      @forums = CfForum.where(
        "forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ? AND permission = ?)",
        current_user.user_id,
        CfForumGroupPermission::ACCESS_MODERATE
      ).order('name ASC').all
    end
  end

  def move
    moving

    @move_to = CfForum.find params[:move_to]
    raise CForum::ForbiddenException unless @forums.include?(@move_to)

    saved = false

    CfThread.transaction do
      @thread.forum_id = @move_to.forum_id
      @thread.save

      @thread.messages.each do |m|
        m.forum_id = @move_to.forum_id
        m.save
      end

      saved = true
    end

    respond_to do |format|
      if saved
        format.html { redirect_to cf_message_url(@thread, @thread.message), notice: t('threads.moved') }
      else
        format.html { render :moving }
      end
    end
  end

  def sticky
    @id     = CfThread.make_id(params)
    @thread = CfThread.find_by_slug!(@id)

    if current_user.admin || current_user.moderate?(current_forum)
      @thread.sticky = !@thread.sticky

      if @thread.save
        redirect_to cf_forum_url(current_forum), notice: @thread.sticky ? I18n.t("threads.stickied") : I18n.t("threads.unstickied")
      else
        redirect_to cf_forum_url(current_forum), alert: I18n.t("threads.sticky_error")
      end
    else
      redirect_to cf_forum_url(current_forum), alert: I18n.t("global.insufficient_rights")
    end
  end

end

# eof
