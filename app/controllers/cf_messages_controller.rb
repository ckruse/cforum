# -*- encoding: utf-8 -*-

require 'digest/sha1'

class CfMessagesController < ApplicationController
  authorize_action([:show, :show_header]) { authorize_forum(permission: :read?) }
  authorize_action([:new, :create, :edit, :update]) { authorize_forum(permission: :write?) }
  authorize_action([:destroy, :restore]) { authorize_forum(permission: :moderator?) }
  authorize_action([:show_retag, :retag]) { may?(RightsHelper::RETAG) }

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

    respond_to do |format|
      format.html do
        if uconf('standard_view', 'thread-view') == 'thread-view'
          notification_center.notify(SHOW_MESSAGE, @thread, @message, @votes)
          render 'show-thread'
        else
          notification_center.notify(SHOW_THREAD, @thread, @message, @votes)
          render 'show-nested'
        end
      end
      format.json { render json: {thread: @thread, message: @message} }
    end
  end

  def message_params
    params.require(:cf_message).permit(:subject, :content, :author,
                                       :email, :homepage)
  end

  def new
    @thread, @message, @id = get_thread_w_post

    raise CForum::ForbiddenException.new if not may_answer(@message)

    @parent  = @message
    @message = CfMessage.new
    @tags    = @parent.tags.map { |t| t.tag_name }

    @max_tags = conf('max_tags_per_message', 3)

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.content = @parent.to_quote(self) if params.has_key?(:quote_old_message)

    notification_center.notify(SHOW_NEW_MESSAGE, @thread, @parent, @message)
  end

  def create
    @thread, @message, @id = get_thread_w_post

    raise CForum::ForbiddenException.new if not may_answer(@message)

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
    @message.ip         = Digest::SHA1.hexdigest(request.remote_ip)

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

  def edit
    @thread, @message, @id = get_thread_w_post

    return unless check_editable(@thread, @message)

    @tags = @message.tags.map { |t| t.tag_name }
    @max_tags = conf('max_tags_per_message', 3)

  end

  def update
    @thread, @message, @id = get_thread_w_post

    return unless check_editable(@thread, @message)

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

    iv_tags = invalid_tags(@tags)
    if not iv_tags.blank?
      invalid = true
      flash[:error] = I18n.t('messages.invalid_tags', tags: iv_tags.join(", "))
    end

    saved = false
    if not invalid and not retvals.include?(false) and not @preview
      CfMessage.transaction do
        raise ActiveRecord::Rollback unless @message.save
        raise ActiveRecord::Rollback unless @message.tags.delete_all
        raise ActiveRecord::Rollback unless save_tags(@message, @tags)
        saved = true
      end
    end

    if saved
      publish('/messages/' + @thread.forum.slug, {type: 'update',
                thread: @thread, message: @message, parent: @parent})
      publish('/messages/all', {type: 'update', thread: @thread,
                message: @message, parent: @parent})

      notification_center.notify(UPDATED_MESSAGE, @thread, @parent,
                                 @message, @tags)
      redirect_to cf_message_path(@thread, @message), notice: I18n.t('messages.updated')
    else
      render :edit
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

  def show_retag
    @thread, @message, @id = get_thread_w_post
    @tags = @message.tags.map { |t| t.tag_name }
    @max_tags = conf('max_tags_per_message', 3)
  end

  def retag
    @thread, @message, @id = get_thread_w_post
    @tags = parse_tags
    invalid = false

    @max_tags = conf('max_tags_per_message', 3).to_i
    if @tags.length > @max_tags
      invalid = true
      flash[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
    end

    iv_tags = invalid_tags(@tags)
    if not iv_tags.blank?
      invalid = true
      flash[:error] = I18n.t('messages.invalid_tags', tags: iv_tags.join(", "))
    end

    saved = false
    if not invalid
      CfMessage.transaction do
        raise ActiveRecord::Rollback unless @message.tags.delete_all
        raise ActiveRecord::Rollback unless save_tags(@message, @tags)
        saved = true
      end
    end

    respond_to do |format|
      if saved
        format.html { redirect_to cf_message_url(@thread, @message), notice: t('messages.retagged') }
        format.json { head :no_content }
      else
        format.html { render :show_retag }
        format.json { render json: {error: flash[:error]} }
      end
    end

  end
end

# eof
