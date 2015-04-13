# -*- encoding: utf-8 -*-

require 'digest/sha1'

class CfThreadsController < ApplicationController
  authorize_action([:index, :show]) { authorize_forum(permission: :read?) }
  authorize_action([:new, :create]) { authorize_forum(permission: :write?) }
  authorize_action([:moving, :move, :sticky]) { authorize_forum(permission: :moderator?) }

  include TagsHelper
  include ThreadsHelper

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_NEW_THREAD  = "show_new_thread"
  NEW_THREAD       = "new_thread"
  NEW_THREAD_SAVED = "new_thread_saved"
  MODIFY_THREADLIST_QUERY_OBJ = 'modify_threadlist_query_obj'

  def index
    index_threads
    ret = notification_center.notify(SHOW_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render json: @threads, include: {:messages => {include: [:owner, :tags]} } }
        format.rss
        format.atom
      end
    end
  end

  def show
    @thread, @id = get_thread

    notification_center.notify(SHOW_THREADLIST, [@thread])

    respond_to do |format|
      format.html { render partial: 'thread', layout: false, locals: { thread: @thread } }
      format.rss
      format.atom
    end
  end

  def message_params
    params.require(:cf_thread).require(:message).permit(:subject, :content, :author, :email, :homepage)
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new
    @tags = []

    @max_tags = conf('max_tags_per_message')

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    invalid = false

    @forum = current_forum

    @thread  = CfThread.new()
    @message = CfMessage.new(message_params)
    @thread.message  =  @message
    @thread.slug     = CfThread.gen_id(@thread)

    if @thread.slug =~ /\/$/ and not @thread.message.subject.blank?
      flash[:error] = t("errors.could_not_generate_slug")
      invalid = true
    end

    @thread.forum_id    = @forum.forum_id
    @message.forum_id   = @forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.content    = CfMessage.to_internal(@message.content)

    @message.created_at = Time.now
    @message.updated_at = @message.created_at
    @message.ip         = Digest::SHA1.hexdigest(request.remote_ip)
    @thread.latest_message = @message.created_at

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

    @max_tags = conf('max_tags_per_message').to_i
    if @tags.length > @max_tags
      invalid = true
      flash[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
    end

    @min_tags = conf('min_tags_per_message').to_i
    if @tags.length < @min_tags
      invalid = true
      flash[:error] = I18n.t('messages.not_enough_tags', min_tags: @min_tags)
    end

    iv_tags = invalid_tags(@tags)
    if not iv_tags.blank?
      invalid = true
      flash[:error] = I18n.t('messages.invalid_tags', tags: iv_tags.join(", "))
    end

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
        rescue ActiveRecord::RecordInvalid
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
        publish('/threads/' + @thread.forum.slug, {type: 'thread', thread: @thread, message: @message})
        publish('/threads/all', {type: 'thread', thread: @thread, message: @message})

        notification_center.notify(NEW_THREAD_SAVED, @thread, @message)

        format.html { redirect_to cf_message_url(@thread, @message), notice: I18n.t("threads.created") }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        @preview = true
        notification_center.notify(SHOW_NEW_THREAD, @thread)

        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def moving
    @id     = CfThread.make_id(params)
    @thread = CfThread.includes(:forum).where(slug: @id).first!
    @thread.gen_tree

    if current_user.admin
      @forums = CfForum.order('name ASC')
    else
      @forums = CfForum.where(
        "forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ? AND permission = ?)",
        current_user.user_id,
        CfForumGroupPermission::ACCESS_MODERATE
      ).order('name ASC')
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

    @thread.sticky = !@thread.sticky

    if @thread.save
      redirect_to cf_forum_url(current_forum), notice: @thread.sticky ? I18n.t("threads.stickied") : I18n.t("threads.unstickied")
    else
      redirect_to cf_forum_url(current_forum), alert: I18n.t("threads.sticky_error")
    end
  end

end

# eof
