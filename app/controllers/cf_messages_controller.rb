# -*- encoding: utf-8 -*-

class CfMessagesController < ApplicationController
  before_filter :authorize!

  include AuthorizeForum

  SHOW_NEW_MESSAGE     = "show_new_message"
  SHOW_MESSAGE         = "show_message"
  CREATING_NEW_MESSAGE = "creating_new_message"
  CREATED_NEW_MESSAGE  = "created_new_message"

  def show
    @id = CfThread.make_id(params)

    conditions = {slug: @id}
    conditions[:messages] = {deleted: false} unless @view_all

    @thread = CfThread.includes(:messages => :owner).where(conditions).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @message.nil?

    notification_center.notify(SHOW_MESSAGE, @thread, @message)

    if current_user and n = CfNotification.find_by_recipient_id_and_oid_and_otype_and_is_read(current_user.user_id, @message.message_id, 'message:create', false)
      if uconf('delete_read_notifications', 'yes') == 'yes'
        n.destroy
      else
        n.is_read = true
        n.save!
      end
    end
  end

  def new
    @id = CfThread.make_id(params)
    @thread = CfThread.includes(:messages).find_by_slug!(@id)
    raise CForum::ForbiddenException.new if @thread.archived and conf('use_archive') == 'yes'

    @parent = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.content = quote_content(@parent.content, uconf('quote_char', '> ')) if uconf('quote_old_message', 'yes') == 'yes'

    notification_center.notify(SHOW_NEW_MESSAGE, @thread, @message)
  end

  def create
    @id = CfThread.make_id(params)
    @thread = CfThread.includes(:messages).find_by_slug!(@id)
    raise CForum::ForbiddenException.new if @thread.archived and conf('use_archive') == 'yes'

    @parent = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    invalid = false

    @message = CfMessage.new(params[:cf_message])
    @message.parent_id  = @parent.message_id
    @message.forum_id   = current_forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.thread_id  = @thread.thread_id

    if current_user
      @message.author     = current_user.username
    else
      unless CfUser.where('LOWER(username) = LOWER(?)', @message.author.strip).first.blank?
        flash[:error] = I18n.t('errors.name_taken')
        invalid = true
      end
    end

    @message.created_at = DateTime.now
    @message.updated_at = DateTime.now

    @message.content    = content_to_internal(@message.content, uconf('quote_char', '> '))

    @preview = true if params[:preview]

    retvals = notification_center.notify(CREATING_NEW_MESSAGE, @thread, @parent, @message)

    unless current_user
      cookies[:cforum_user] = {value: request.uuid, expires: 1.year.from_now} if cookies[:cforum_user].blank?
      @message.uuid = cookies[:cforum_user]

      cookies[:cforum_author]   = {value: @message.author, expires: 1.year.from_now}
      cookies[:cforum_email]    = {value: @message.email, expires: 1.year.from_now}
      cookies[:cforum_homepage] = {value: @message.homepage, expires: 1.year.from_now}
    end

    if not invalid and not retvals.include?(false) and not @preview and @message.save
      notification_center.notify(CREATED_NEW_MESSAGE, @thread, @parent, @message)
      peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: @thread.thread_id, message: @message.message_id})

      redirect_to cf_message_path(@thread, @message), :notice => I18n.t('messages.created')
    else
      render :new
    end
  end

  def destroy
    @id     = CfThread.make_id(params)
    @thread = CfThread.includes(:messages, :forum).find_by_slug!(@id)

    @message = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @message.blank?

    CfMessage.transaction do
      @message.delete_with_subtree
    end

    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message, :view_all => true), notice: I18n.t('messages.destroyed') }
      format.json { head :no_content }
    end
  end

  def restore
    @id     = CfThread.make_id(params)
    @thread = CfThread.includes(:messages, :forum).find_by_slug!(@id)

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.blank?

    CfMessage.transaction do
      @message.restore_with_subtree
    end

    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message, :view_all => true), notice: I18n.t('messages.restored') }
      format.json { head :no_content }
    end
  end
end

SettingValidator.validators['quote_old_message'] = lambda { |nam, val| %w{yes no}.include?(val) }

# eof
