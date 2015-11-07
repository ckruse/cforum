# -*- encoding: utf-8 -*-

require 'digest/sha1'

class CfThreadsController < ApplicationController
  authorize_action([:index, :show]) { authorize_forum(permission: :read?) }
  authorize_action([:new, :create]) { authorize_forum(permission: :write?) }
  authorize_action([:moving, :move, :sticky]) { authorize_forum(permission: :moderator?) }

  include TagsHelper
  include ThreadsHelper
  include MentionsHelper

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_NEW_THREAD  = "show_new_thread"
  NEW_THREAD       = "new_thread"
  NEW_THREAD_SAVED = "new_thread_saved"
  MODIFY_THREADLIST_QUERY_OBJ = 'modify_threadlist_query_obj'
  THREAD_MOVED     = "thread_moved"

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
    params.require(:cf_thread).require(:message).permit(:subject, :content, :author,
                                                        :email, :homepage, :problematic_site)
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new(params[:cf_thread].blank? ? {} :
                                      message_params)
    @tags = parse_tags

    @max_tags = conf('max_tags_per_message')

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    invalid = false

    @forum = current_forum
    if @forum.blank?
      @forum = CfForum.
               where(forum_id: params[:cf_thread][:forum_id]).
               where("forum_id IN (" + CfForum.visible_sql(current_user) + ')').first!
    end

    @thread  = CfThread.new()
    @message = CfMessage.new(message_params)
    @thread.message  =  @message
    @thread.slug     = CfThread.gen_id(@thread)

    if @thread.slug =~ /\/$/ and not @thread.message.subject.blank?
      flash.now[:error] = t("errors.could_not_generate_slug")
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
    elsif not @message.author.blank?
      unless CfUser.where('LOWER(username) = LOWER(?)', @message.author.strip).first.blank?
        flash.now[:error] = I18n.t('errors.name_taken')
        invalid = true
      end
    end

    @tags    = parse_tags
    @preview = true if params[:preview]
    retvals  = notification_center.notify(NEW_THREAD, @thread, @message, @tags)

    @max_tags = conf('max_tags_per_message').to_i
    if @tags.length > @max_tags
      invalid = true
      flash.now[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
    end

    @min_tags = conf('min_tags_per_message').to_i
    if @tags.length < @min_tags
      invalid = true
      flash.now[:error] = I18n.t('messages.not_enough_tags', count: @min_tags)
    end

    iv_tags = invalid_tags(@forum, @tags)
    if not iv_tags.blank?
      invalid = true
      flash.now[:error] = t('messages.invalid_tags', count: iv_tags.length, tags: iv_tags.join(", "))
    end

    unless current_user
      cookies[:cforum_user] = {value: request.uuid, expires: 1.year.from_now} if cookies[:cforum_user].blank?
      @message.uuid = cookies[:cforum_user]

      cookies[:cforum_author]   = {value: @message.author, expires: 1.year.from_now}
      cookies[:cforum_email]    = {value: @message.email, expires: 1.year.from_now}
      cookies[:cforum_homepage] = {value: @message.homepage, expires: 1.year.from_now}
    end

    set_mentions(@message)

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

        save_tags(@forum, @message, @tags)

        @thread.messages << @message
        audit(@thread, 'create')

        saved = true
      end
    end

    respond_to do |format|
      if not @preview and saved
        publish('thread:create', {type: 'thread', thread: @thread,
                                  message: @message},
                '/forums/' + @forum.slug)

        notification_center.notify(NEW_THREAD_SAVED, @thread, @message)

        format.html { redirect_to cf_message_url(@thread, @message), notice: I18n.t("threads.created") }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        # provoke a validation in case of missing tags
        @thread.message.valid? unless @preview
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
    @forum   = @thread.forum
    raise CForum::ForbiddenException unless @forums.include?(@move_to)

    saved = false

    CfThread.transaction do
      @thread.forum_id = @move_to.forum_id
      @thread.save
      audit(@thread, 'move')

      @thread.messages.each do |m|
        m.forum_id = @move_to.forum_id
        m.save
        audit(m, 'move')
      end

      saved = true
    end

    respond_to do |format|
      if saved
        notification_center.notify(THREAD_MOVED, @thread, @forum, @move_to)
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
      audit(@thread, @thread.sticky ? 'sticky' : 'unsticky')
      redirect_to cf_forum_url(current_forum), notice: @thread.sticky ? I18n.t("threads.stickied") : I18n.t("threads.unstickied")
    else
      redirect_to cf_forum_url(current_forum), alert: I18n.t("threads.sticky_error")
    end
  end

  def redirect_to_page
    if params[:tid].blank?
      render status: 404
      return
    end

    if uconf('page_messages') == 'yes'
      threads, sticky_threads = index_threads(true, -1, -1, false, true)
      threads.gsub!(/SELECT.*?FROM/, 'SELECT threads.thread_id FROM')
      sticky_threads.gsub!(/SELECT.*?FROM/, 'SELECT COUNT(*) FROM').gsub!(/ORDER BY.*/, '')

      threads = CfThread.connection.execute threads
      sticky_threads = CfThread.connection.execute sticky_threads

      tid = params[:tid].to_i
      pos = 0
      found = false
      prev = nil

      threads.each do |row|
        if row['thread_id'].to_i == tid
          found = true
          break
        end

        if prev == nil || prev != row['thread_id']
          pos += 1
          prev = row['thread_id']
        end
      end

      unless found
        redirect_to cf_forum_url(current_forum) + '#t' + params[:tid]
        return
      end

      paging = uconf('pagination').to_i
      paging -= sticky_threads[0]['count'].to_i
      page = pos / paging

      redirect_to cf_forum_url(current_forum, p: page) + '#t' + params[:tid]
    else
      redirect_to cf_forum_url(current_forum) + '#t' + params[:tid]
    end
  end

end

# eof
