# -*- encoding: utf-8 -*-

class CfThreadsController < ApplicationController
  before_filter :authorize!

  include AuthorizeForum

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_THREAD      = "show_thread"
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

      unless @view_all
        crits << "EXISTS(SELECT message_id FROM messages WHERE thread_id = threads.thread_id AND deleted = false)"
      end
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

      unless @view_all
        crits << "EXISTS(SELECT message_id FROM messages WHERE thread_id = threads.thread_id AND deleted = false)"
      end
    end
    sql << crits.join(" AND ")
    sql << " ORDER BY threads.created_at DESC LIMIT #{@limit} OFFSET #{@limit * @page}"

    result = CfThread.connection.execute(sql)

    ids = []
    result.each do |row|
      ids << row['thread_id'].to_i
    end

    @threads = CfThread.
      preload(:forum, :tags).
      includes(:messages => :owner).
      where(conditions).
      where(thread_id: ids).
      order('threads.created_at DESC').
      all

    if forum
      rslt = CfForum.connection.execute("SELECT counter_table_get_count('threads', " +
        current_forum.forum_id.to_s +
        ") AS cnt")
    else
      rslt = CfForum.connection.execute("SELECT SUM(difference) AS cnt FROM counter_table WHERE table_name = 'threads'")
    end

    @all_threads_count = rslt[0]['cnt'].to_i

    notification_center.notify(SHOW_THREADLIST, @threads)
  end

  def show
    @id = CfThread.make_id(params)

    conditions = {slug: @id}
    conditions[:messages] = {deleted: false} unless @view_all

    @thread = CfThread.includes(:messages => :owner).where(conditions).first
    raise CForum::NotFoundException.new if @thread.blank?

    notification_center.notify(SHOW_THREAD, @thread)
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

    @forum = current_forum

    @thread  = CfThread.new()
    @message = CfMessage.new(params[:cf_thread][:message])
    @thread.message  =  @message
    @thread.slug     = CfThread.gen_id(@thread)

    @thread.forum_id    = @forum.forum_id
    @message.forum_id   = @forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.content    = content_to_internal(@message.content, uconf('quote_char', '> '))

    @message.created_at = DateTime.now
    @message.updated_at = DateTime.now

    @tags = []
    if not params[:tags].blank?
      @tags = (params[:tags].map {|s| s.strip.downcase}).uniq
    # non-js variant for conservative people
    elsif not params[:tag_list].blank?
      @tags = (params[:tag_list].split(',').map {|s| s.strip.downcase}).uniq
    end

    retvals = notification_center.notify(NEW_THREAD, @thread, @message, @tags)

    @preview = true if params[:preview]

    saved = false
    if not @preview and not retvals.include?(false)
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

        save_tags(@thread, @tags)

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
        format.html { redirect_to cf_message_url(@thread, @thread.message), notice: t('threads.moved') } # TODO: I18n
      else
        format.html { render :moving }
      end
    end
  end

  private
  def save_tags(thread, tags)
    tag_objs = []

    # first check if all tags are present
    unless tags.empty?
      tag_objs = CfTag.where('forum_id = ? AND LOWER(tag_name) IN (?)', current_forum.forum_id, tags).all
      tags.each do |t|
        tag_obj = tag_objs.find {|to| to.tag_name.downcase == t}

        if tag_obj.blank?
          # create a savepoint (rails implements savepoints as nested transactions)
          tag_obj = CfTag.create(forum_id: current_forum.forum_id, tag_name: t)

          if tag_obj.tag_id.blank?
            saved = false
            flash[:error] = 'Tag is invalid' # TODO: i18n/l10n
            raise ActiveRecord::Rollback.new
          end

          tag_objs << tag_obj
        end
      end

      # then create the tag/thread connections
      tag_objs.each do |to|
        CfTagThread.create!(tag_id: to.tag_id, thread_id: thread.thread_id)
      end
    end

    thread.tags = tag_objs
    tag_objs
  end # save_tags
end

# eof
