# -*- encoding: utf-8 -*-

require 'digest/sha1'

class CfMessagesController < ApplicationController
  authorize_action([:show, :show_header, :versions]) { authorize_forum(permission: :read?) }
  authorize_action([:new, :create, :edit, :update]) { authorize_forum(permission: :write?) }
  authorize_action([:destroy, :restore]) { authorize_forum(permission: :moderator?) }
  authorize_action([:show_retag, :retag]) { may?(RightsHelper::RETAG) }

  include TagsHelper
  include MentionsHelper

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

    if not current_forum.blank? and @message.forum_id != current_forum.forum_id
      redirect_to cf_message_url(@thread, @message), status: 301
      return
    end

    @parent = @message.parent_level

    # parameter overwrites cookie overwrites config; validation
    # overwrites everything
    @read_mode = uconf('standard_view')
    @read_mode = cookies[:cf_readmode] if not cookies[:cf_readmode].blank? and current_user.blank?
    @read_mode = params[:rm] unless params[:rm].blank?
    @read_mode = 'thread-view' unless %w(thread-view nested-view).include?(@read_mode)

    if not params[:rm].blank? and current_user.blank?
      cookies[:cf_readmode] = {value: @read_mode, expires: 1.year.from_now}
    end


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
        if @read_mode == 'thread-view'
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

  def edit_message_params
    fields = [:subject, :content, :email, :homepage, :problematic_site]
    fields << :author if current_user.try(:admin?)

    params.require(:cf_message).permit(fields)
  end

  def message_params
    params.require(:cf_message).permit(:subject, :content, :author,
                                       :email, :homepage, :problematic_site)
  end

  def new
    @thread, @message, @id = get_thread_w_post

    raise CForum::ForbiddenException.new if not may_answer(@message)

    @parent  = @message
    @message = CfMessage.new
    @tags    = @parent.tags.map { |t| t.tag_name }

    @max_tags = conf('max_tags_per_message')

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.problematic_site = @parent.problematic_site
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
    @message.forum_id   = @thread.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.thread_id  = @thread.thread_id

    @message.content    = CfMessage.to_internal(@message.content)

    @message.created_at = Time.now
    @message.updated_at = @message.created_at
    @message.ip         = Digest::SHA1.hexdigest(request.remote_ip)

    set_mentions(@message)

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
    retvals  = notification_center.notify(CREATING_NEW_MESSAGE, @thread, @parent, @message, @tags)

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

    iv_tags = invalid_tags(current_forum, @tags)
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

    saved = false
    if not invalid and not retvals.include?(false) and not @preview
      CfMessage.transaction do
        raise ActiveRecord::Rollback unless @message.save
        raise ActiveRecord::Rollback unless save_tags(current_forum, @message, @tags)

        @message.reload
        audit(@message, 'create')

        saved = true
      end
    end

    if saved
      publish('message:create', {type: 'message', thread: @thread,
                                 message: @message, parent: @parent},
              '/forums/' + current_forum.slug)

      notification_center.notify(CREATED_NEW_MESSAGE, @thread, @parent, @message, @tags)
      redirect_to cf_message_url(@thread, @message), :notice => I18n.t('messages.created')
    else
      @message.valid? unless @preview
      @preview = true
      notification_center.notify(SHOW_NEW_MESSAGE, @thread, @parent, @message)
      render :new
    end
  end

  def edit
    @thread, @message, @id = get_thread_w_post

    return unless check_editable(@thread, @message)

    @tags = @message.tags.map { |t| t.tag_name }
    @max_tags = conf('max_tags_per_message')
    @edit = true

    notification_center.notify(SHOW_MESSAGE, @thread, @message, {})
  end

  def update
    @thread, @message, @id = get_thread_w_post
    @tags = parse_tags

    unless check_editable(@thread, @message, false)
      @parent = @message
      @message = CfMessage.new(message_params)

      flash.now[:error] = t('messages.editing_not_allowed_should_we_create_followup')

      render :new
      return
    end

    invalid  = false

    @message.attributes = edit_message_params
    @message.content    = CfMessage.to_internal(@message.content)

    set_mentions(@message)

    del_versions = params[:delete_previous_versions] == '1' and current_user.admin?

    if (@message.content_changed? or @message.subject_changed? or @message.author_changed?) and not del_versions
      @version = CfMessageVersion.new
      @version.subject = @message.subject_was
      @version.content = @message.content_was
      @version.message_id = @message.message_id

      if not current_user.blank?
        @message.editor_id  = current_user.user_id
        @message.edit_author = current_user.username
        @version.user_id = current_user.user_id
        @version.author = current_user.username
      else
        @message.editor_id = nil
        @message.edit_author = @message.author
        @version.author = @message.author
      end
    end

    @preview = true if params[:preview]
    retvals  = notification_center.notify(UPDATING_MESSAGE, @thread, @message,
                                          @tags)
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

    iv_tags = invalid_tags(current_forum, @tags)
    if not iv_tags.blank?
      invalid = true
      flash.now[:error] = t('messages.invalid_tags', count: iv_tags.length, tags: iv_tags.join(", "))
    end

    saved = false
    if not invalid and not retvals.include?(false) and not @preview
      CfMessage.transaction do
        if @message.save
          audit(@message, 'update')
        else
          raise ActiveRecord::Rollback
        end

        @message.tags.delete_all
        if save_tags(current_forum, @message, @tags)
          audit(@message, 'retag')
        else
          raise ActiveRecord::Rollback
        end

        if del_versions
          audit(@message, 'del_versions')
          CfMessageVersion.delete_all(['message_id = ?', @message.message_id])
        else
          raise ActiveRecord::Rollback if @version and not @version.save
        end

        if params[:retag_answers] == '1' and may?(RightsHelper::RETAG)
          @message.all_answers do |m|
            m.tags.delete_all

            if save_tags(current_forum, m, @tags)
              audit(@message, 'retag')
            else
              raise ActiveRecord::Rollback
            end
          end
        end

        saved = true
      end
    end

    if saved
      publish('message:update', {type: 'update', thread: @thread,
                                 message: @message, parent: @parent},
              '/forums/' + current_forum.slug)

      notification_center.notify(UPDATED_MESSAGE, @thread, @parent,
                                 @message, @tags)
      redirect_to cf_message_url(@thread, @message), notice: I18n.t('messages.updated')
    else
      @message.valid? unless @preview
      @edit = true
      notification_center.notify(SHOW_MESSAGE, @thread, @message, {})
      render :edit
    end
  end

  def versions
    @thread, @message, @id = get_thread_w_post
  end

  def destroy
    @thread, @message, @id = get_thread_w_post

    retvals = notification_center.notify(DELETING_MESSAGE, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        @message.delete_with_subtree
        audit(@message, 'delete')
      end
      notification_center.notify(DELETED_MESSAGE, @thread, @message)
    end

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message, view_all: true), notice: I18n.t('messages.destroyed') }
      format.json { head :no_content }
    end
  end

  def restore
    @thread, @message, @id = get_thread_w_post

    retvals = notification_center.notify(RESTORING_MESSAGE, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        @message.restore_with_subtree
        audit(@message, 'restore')
      end
      notification_center.notify(RESTORED_MESSAGE, @thread, @message)
    end

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message, view_all: true), notice: I18n.t('messages.restored') }
      format.json { head :no_content }
    end
  end

  def show_retag
    @thread, @message, @id = get_thread_w_post
    @tags = @message.tags.map { |t| t.tag_name }
    @max_tags = conf('max_tags_per_message')
  end

  def retag
    @thread, @message, @id = get_thread_w_post
    @tags = parse_tags
    invalid = false

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

    iv_tags = invalid_tags(current_forum, @tags)
    if not iv_tags.blank?
      invalid = true
      flash.now[:error] = t('messages.invalid_tags', count: iv_tags.length, tags: iv_tags.join(", "))
    end

    saved = false
    if not invalid
      CfMessage.transaction do
        @message.tags.delete_all

        if save_tags(current_forum, @message, @tags)
          @message.reload
          audit(@message, 'retag')
        else
          raise ActiveRecord::Rollback
        end

        if params[:retag_answers] == '1'
          @message.all_answers do |m|
            m.tags.delete_all
            if save_tags(current_forum, m, @tags)
              m.reload
              audit(m, 'retag')
            else
              raise ActiveRecord::Rollback
            end
          end
        end

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

  def preview
    m = CfMessage.new(content: params[:content])
    render text: m.to_html(self)
  end
end

# eof
