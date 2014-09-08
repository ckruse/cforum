# -*- encoding: utf-8 -*-

class CfMessagesController < ApplicationController
  before_filter :authorize!

  include AuthorizeForum
  include TagsHelper

  SHOW_NEW_MESSAGE     = "show_new_message"
  SHOW_MESSAGE         = "show_message"
  SHOW_THREAD          = "show_thread"

  CREATING_NEW_MESSAGE = "creating_new_message"
  CREATED_NEW_MESSAGE  = "created_new_message"

  UPDATING_MESSAGE     = "updating_message"
  UPDATED_MESSAGE      = "updated_message"

  DELETING_MESSAGE     = "deleting_message"
  DELETED_MESSAGE      = "deleted_message"

  RESTORING_MESSAGE    = "restoring_message"
  RESTORED_MESSAGE     = "restored_message"

  def show
    @thread, @message, @id = get_thread_w_post

    @parent = @message.parent_level

    if current_user
      mids = @thread.messages.map {|m| m.message_id}
      votes = CfVote.where(user_id: current_user.user_id, message_id: mids)
      @votes = {}

      votes.each do |v|
        @votes[v.message_id] = v
      end
    end

    if uconf('standard_view', 'thread-view') == 'thread-view'
      notification_center.notify(SHOW_MESSAGE, @thread, @message, @votes)
      render 'show-thread'
    else
      notification_center.notify(SHOW_THREAD, @thread, @message, @votes)
      render 'show-nested'
    end
  end

  def show_header
    @thread = CfThread.find params[:id]
    @message = @thread.find_message!(params[:mid].to_i)
    render layout: false
  end

  def message_params
    params.require(:cf_message).permit(:subject, :content, :author, :email, :homepage)
  end

  def new
    @thread, @message, @id = get_thread_w_post

    @parent  = @message
    @message = CfMessage.new
    @tags    = @parent.tags.map { |t| t.tag_name }

    @max_tags = conf('max_tags_per_message', 3)

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.content = @parent.to_quote if params.has_key?(:quote_old_message)

    notification_center.notify(SHOW_NEW_MESSAGE, @thread, @parent, @message)
  end

  def create
    @thread, @message, @id = get_thread_w_post

    invalid  = false

    @parent  = @message
    @message = CfMessage.new(message_params)

    @message.parent_id  = @parent.message_id
    @message.forum_id   = current_forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.thread_id  = @thread.thread_id

    @message.content    = CfMessage.to_internal(@message.content)

    @message.created_at = Time.now
    @message.updated_at = @message.created_at

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
    retvals  = notification_center.notify(CREATING_NEW_MESSAGE, @thread, @parent, @message, @tags)

    @max_tags = conf('max_tags_per_message', 3).to_i
    if @tags.length > @max_tags
      invalid = true
      flash[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
    end

    unless current_user
      cookies[:cforum_user] = {value: request.uuid, expires: 1.year.from_now} if cookies[:cforum_user].blank?
      @message.uuid = cookies[:cforum_user]

      cookies[:cforum_author]   = {value: @message.author, expires: 1.year.from_now}
      cookies[:cforum_email]    = {value: @message.email, expires: 1.year.from_now}
      cookies[:cforum_homepage] = {value: @message.homepage, expires: 1.year.from_now}
    end

    saved = false
    if not invalid and not retvals.include?(false) and not @preview
      CfMessage.transaction do
        raise ActiveRecord::Rollback unless @message.save
        raise ActiveRecord::Rollback unless save_tags(@message, @tags)
        saved = true
      end
    end

    if saved
      publish('/messages/' + @thread.forum.slug, {type: 'message', thread: @thread, message: @message, parent: @parent})
      publish('/messages/all', {type: 'message', thread: @thread, message: @message, parent: @parent})

      notification_center.notify(CREATED_NEW_MESSAGE, @thread, @parent, @message, @tags)
      redirect_to cf_message_path(@thread, @message), :notice => I18n.t('messages.created')
    else
      render :new
    end
  end

  def check_editable
    @max_editable_age = conf('max_editable_age', 10).to_i

    @thread, @message, @id = get_thread_w_post
    edit_it = false
    too_old = false

    if @message.created_at <= @max_editable_age.minutes.ago
      too_old = true
    end

    if not current_user and
        not cookies[:cforum_user].blank? and
        @message.uuid == cookies[:cforum_user] and not too_old
      edit_it = true
    elsif current_user and
        not current_forum.moderator?(current_user) and
        current_user.user_id == @message.user_id and
        not too_old
      edit_it = true
    elsif current_user and current_forum.moderator?(current_user)
      edit_it = true
    end

    unless edit_it
      if too_old
        flash[:error] = t('messages.message_too_old_to_edit',
                          minutes: @max_editable_age)
      else
        flash[:error] = t('messages.only_author_or_mod_may_edit')
      end

      redirect_to cf_message_url(@thread, @message)
      return
    end

    return true
  end

  def edit
    return unless check_editable

    @tags = @message.tags.map { |t| t.tag_name }

  end

  def update
    return unless check_editable

    invalid  = false

    @message.attributes = message_params
    @message.content    = CfMessage.to_internal(@message.content)

    @tags    = parse_tags
    @preview = true if params[:preview]
    retvals  = notification_center.notify(UPDATING_MESSAGE, @thread, @message,
                                          @tags)

    @max_tags = conf('max_tags_per_message', 3).to_i
    if @tags.length > @max_tags
      invalid = true
      flash[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
    end

    saved = false
    if not invalid and not retvals.include?(false) and not @preview
      CfMessage.transaction do
        raise ActiveRecord::Rollback unless @message.save
        raise ActiveRecord::Rollback unless save_tags(@message, @tags)
        saved = true
      end
    end

    if saved
      publish('/messages/' + @thread.forum.slug, {type: 'message',
                thread: @thread, message: @message, parent: @parent})
      publish('/messages/all', {type: 'message', thread: @thread,
                message: @message, parent: @parent})

      notification_center.notify(UPDATED_MESSAGE, @thread, @parent,
                                 @message, @tags)
      redirect_to cf_message_path(@thread, @message), notice: I18n.t('messages.updated')
    else
      render :new
    end
  end

  def destroy
    @thread, @message, @id = get_thread_w_post

    retvals = notification_center.notify(DELETING_MESSAGE, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        @message.delete_with_subtree
      end
      notification_center.notify(DELETED_MESSAGE, @thread, @message)
    end

    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message, :view_all => true), notice: I18n.t('messages.destroyed') }
      format.json { head :no_content }
    end
  end

  def restore
    @thread, @message, @id = get_thread_w_post

    retvals = notification_center.notify(RESTORING_MESSAGE, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        @message.restore_with_subtree
      end
      notification_center.notify(RESTORED_MESSAGE, @thread, @message)
    end

    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message, :view_all => true), notice: I18n.t('messages.restored') }
      format.json { head :no_content }
    end
  end

end

# eof
