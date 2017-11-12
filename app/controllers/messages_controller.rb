require 'digest/sha1'

class MessagesController < ApplicationController
  authorize_action(%i[show show_header versions]) { authorize_forum(permission: :read?) }
  authorize_action(%i[new create edit update]) { authorize_forum(permission: :write?) }
  authorize_action(%i[destroy restore]) { authorize_forum(permission: :moderator?) }
  authorize_action(%i[show_retag retag]) { may?(Badge::RETAG) }

  include TagsHelper
  include MentionsHelper
  include ReferencesHelper
  include UserDataHelper
  include SuspiciousHelper
  include HighlightHelper
  include SearchHelper
  include InterestingHelper
  include SpamHelper
  include LinkTagsHelper
  include NotifyHelper
  include SubscriptionsHelper
  include NewMessageHelper
  include TransientInfosHelper

  def show
    @thread, @message, @id = get_thread_w_post

    if current_forum.present? && (@message.forum_id != current_forum.forum_id)
      redirect_to message_url(@thread, @message), status: 301
      return
    end

    @parent = @message.parent_level

    # parameter overwrites cookie overwrites config; validation
    # overwrites everything
    @read_mode = uconf('standard_view')
    @read_mode = cookies[:cf_readmode] if cookies[:cf_readmode].present? && current_user.blank?
    @read_mode = params[:rm] if params[:rm].present?
    @read_mode = 'thread-view' unless %w[thread-view nested-view].include?(@read_mode)

    @new_message = new_message(@message, uconf('quote_by_default') == 'yes' && @read_mode != 'nested-view')
    @max_tags = conf('max_tags_per_message')
    show_new_message_functions(@thread, @message, @new_message, false)

    if params[:rm].present? && current_user.blank?
      cookies[:cf_readmode] = { value: @read_mode, expires: 1.year.from_now }
    end

    if current_user
      mids = @thread.messages.map(&:message_id)
      votes = Vote.where(user_id: current_user.user_id, message_id: mids)
      @votes = {}

      votes.each do |v|
        @votes[v.message_id] = v
      end
    end

    show_message_funtions(@thread, @message, @read_mode == 'thread-view' ? :thread : :nested)

    respond_to do |format|
      format.html do
        if @read_mode == 'thread-view'
          render 'show-thread'
        else
          render 'show-nested'
        end
      end
      format.json { render json: { thread: @thread, message: @message } }
    end
  end

  def edit_message_params
    fields = %i[subject content email homepage problematic_site]
    fields << :author if current_user.try(:admin?)

    params.require(:message).permit(fields)
  end

  def message_params
    params.require(:message).permit(:subject, :content, :author,
                                    :email, :homepage, :problematic_site)
  end

  def new
    @thread, @parent, @id = get_thread_w_post

    raise CForum::ForbiddenException unless may_answer?(@parent)

    @tags = @parent.tags.map(&:tag_name)
    @max_tags = conf('max_tags_per_message')

    with_quote = if params[:with_quote].blank?
                   uconf('quote_by_default') == 'yes'
                 else
                   params[:with_quote] == 'yes'
                 end

    # inherit message and subject from previous post
    @message = new_message(@parent, with_quote)

    show_new_message_functions(@thread, @parent, @message, @preview)
  end

  def show_quote
    @thread, @parent, @id = get_thread_w_post

    raise CForum::ForbiddenException unless may_answer?(@parent)

    if params[:only_quote]
      render plain: @parent.to_quote(self)
    else
      @message = new_message(@parent, params[:quote] == 'yes')
      show_new_message_functions(@thread, @parent, @message, @preview)
      render plain: @message.content
    end
  end

  def create
    @thread, @message, @id = get_thread_w_post

    raise CForum::ForbiddenException unless may_answer?(@message)

    invalid  = false

    @parent  = @message
    @message = Message.new(message_params)

    set_message_attibutes(@message, @thread, current_user, @parent)
    save_mentions(@message)

    invalid = true unless message_author(@message)

    @tags    = parse_tags
    @preview = true if params[:preview]

    invalid = true unless validate_tags(@tags)
    if spam?(@message)
      invalid = true
      flash.now[:error] = t('global.spam_filter')
    end

    save_user_cookies(@message)

    saved = false
    if !invalid && !@preview
      Message.transaction do
        raise ActiveRecord::Rollback unless @message.save
        raise ActiveRecord::Rollback unless save_tags(current_forum, @message, @tags)

        @message.reload
        save_references(@message)
        audit(@message, 'create')

        saved = true
      end
    end

    if saved
      new_message_saved(@thread, @message, @parent, current_forum)
      redirect_to message_url(@thread, @message), notice: I18n.t('messages.created')
    else
      @message.valid? unless @preview
      @preview = true

      show_new_message_functions(@thread, @parent, @message, @preview)

      render :new
    end
  end

  def edit
    @thread, @message, @id = get_thread_w_post

    return unless check_editable(@thread, @message)

    @tags = @message.tags.map(&:tag_name)
    @max_tags = conf('max_tags_per_message')
    @edit = true

    flash.now[:error] = t('messages.edit_change_to_markdown') if @message.format != 'markdown'

    show_message_funtions(@thread, @message)
  end

  def update
    @thread, @message, @id = get_thread_w_post
    @tags = parse_tags

    unless check_editable(@thread, @message, false)
      @parent = @message
      @message = Message.new(message_params)

      flash.now[:error] = t('messages.editing_not_allowed_should_we_create_followup')

      render :new
      return
    end

    invalid = false

    @message.attributes = edit_message_params
    @message.content    = Message.to_internal(@message.content)

    save_mentions(@message)

    (del_versions = params[:delete_previous_versions] == '1') && current_user.admin?

    if @message.format != 'markdown'
      del_versions = true
      @message.format = 'markdown'
    end

    if (@message.content_changed? || @message.subject_changed? || @message.author_changed?) && !del_versions
      @version = MessageVersion.new
      @version.subject = @message.subject_was
      @version.content = @message.content_was
      @version.message_id = @message.message_id

      if current_user.present?
        @message.editor_id = current_user.user_id
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
    invalid = true unless validate_tags(@tags)

    saved = false
    if !invalid && !@preview
      Message.transaction do
        raise ActiveRecord::Rollback unless @message.save

        save_references(@message)
        audit(@message, 'update')

        @message.tags.delete_all
        raise ActiveRecord::Rollback unless save_tags(current_forum, @message, @tags)
        audit(@message, 'retag')

        if del_versions
          audit(@message, 'del_versions')
          MessageVersion.where(message_id: @message.message_id).delete_all
        elsif @version && !@version.save
          raise ActiveRecord::Rollback
        end

        if (params[:retag_answers] == '1') && may?(Badge::RETAG)
          @message.all_answers do |m|
            m.tags.delete_all

            raise ActiveRecord::Rollback unless save_tags(current_forum, m, @tags)
            audit(@message, 'retag')
          end
        end

        saved = true
      end
    end

    if saved
      BroadcastMessageJob.perform_later(@message.message_id, 'message', 'update')
      search_index_message(@thread, @message)
      redirect_to message_url(@thread, @message), notice: I18n.t('messages.updated')
    else
      @message.valid? unless @preview
      @edit = true

      show_message_funtions(@thread, @message)
      render :edit
    end
  end

  def versions
    @thread, @message, @id = get_thread_w_post
  end

  def destroy
    @thread, @message, @id = get_thread_w_post

    Message.transaction do
      @message.delete_with_subtree
      audit(@message, 'delete')
    end

    search_unindex_message_with_answers(@message)

    unnotify_user(@message.message_id, ['message:create-answer', 'message:create-activity'])

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message, view_all: true), notice: I18n.t('messages.destroyed') }
      format.json { head :no_content }
    end
  end

  def restore
    @thread, @message, @id = get_thread_w_post

    Message.transaction do
      @message.restore_with_subtree
      audit(@message, 'restore')
    end

    search_index_message(@thread, @message)
    NotifyNewMessageJob.perform_later(@thread.thread_id, @message.message_id, 'message')

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message, view_all: true), notice: I18n.t('messages.restored') }
      format.json { head :no_content }
    end
  end

  def show_retag
    @thread, @message, @id = get_thread_w_post
    @tags = @message.tags.map(&:tag_name)
    @max_tags = conf('max_tags_per_message')
  end

  def retag
    @thread, @message, @id = get_thread_w_post
    @tags = parse_tags

    invalid = false
    invalid = true unless validate_tags(@tags)

    saved = false
    unless invalid
      Message.transaction do
        @message.tags.delete_all

        raise ActiveRecord::Rollback unless save_tags(current_forum, @message, @tags)
        @message.reload
        audit(@message, 'retag')

        if params[:retag_answers] == '1'
          @message.all_answers do |m|
            m.tags.delete_all
            raise ActiveRecord::Rollback unless save_tags(current_forum, m, @tags)
            m.reload
            audit(m, 'retag')
          end
        end

        saved = true
      end
    end

    respond_to do |format|
      if saved
        format.html { redirect_to message_url(@thread, @message), notice: t('messages.retagged') }
        format.json { head :no_content }
      else
        format.html { render :show_retag }
        format.json { render json: { error: flash[:error] } }
      end
    end
  end

  def preview
    m = Message.new(content: params[:content])
    save_mentions(m)
    render html: m.to_html(self)
  end

  def show_message_funtions(thread, message, type = :thread)
    check_threads_for_suspiciousness([thread])
    check_threads_for_highlighting([thread])
    mark_threads_interesting([thread])
    mark_threads_subscribed([thread])

    if type == :thread
      show_thread_link_tags(thread, message)
      mark_message_read(thread, message)
      transient_infos if check_for_deleting_notification(thread, message)
    else
      show_message_link_tags(thread, message)
      mark_thread_read(thread)
      unnotify_for_thread(thread)
    end
  end

  def show_new_message_functions(thread, parent, message, preview)
    set_user_data_vars(message, parent) unless preview
    check_threads_for_highlighting([thread])
    mark_threads_interesting([thread])
    mark_message_read(thread, parent)
  end

  def unnotify_for_thread(thread)
    return if current_user.blank?

    had_one = false
    message_ids = thread.messages.map(&:message_id)

    to_delete = []
    to_mark_read = []
    notifications = Notification
                      .where(recipient_id: current_user.user_id,
                             oid: message_ids)
                      .where("otype IN ('message:create-answer','message:create-activity', 'message:mention')")
                      .all

    notifications.each do |n|
      had_one = true

      if (n.otype.in?(['message:create-answer', 'message:create-activity']) &&
          uconf('delete_read_notifications_on_abonements') == 'yes') ||
         (n.otype == 'message:mention' &&
          uconf('delete_read_notifications_on_mention') == 'yes')
        to_delete << n.notification_id
      else
        to_mark_read << n.notification_id
      end
    end

    Notification.where(notification_id: to_delete).delete_all if to_delete.present?
    Notification.where(notification_id: to_mark_read).update_all(is_read: true) if to_mark_read.present?

    return unless had_one
    BroadcastUserJob.perform_later({ type: 'notification:update',
                                     unread: unread_notifications },
                                   current_user.user_id)

    notifications
  end

  def new_message(parent, quote = false)
    message = Message.new
    message.subject = parent.subject
    message.problematic_site = parent.problematic_site
    message.content = parent.to_quote(self) if quote

    message
  end
end

# eof
