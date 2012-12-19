# -*- encoding: utf-8 -*-

class CfMessagesController < ApplicationController
  before_filter :authorize!

  SHOW_NEW_MESSAGE = "show_new_message"
  SHOW_MESSAGE = "show_message"

  def show
    @id = CfThread.make_id(params)

    conditions = {slug: @id}
    conditions[:messages] = {deleted: false} unless @view_all

    @thread = CfThread.includes(:messages => :owner).where(conditions).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @message.nil?

    notification_center.notify(SHOW_MESSAGE, @thread, @message)
  end

  def new
    @id = CfThread.make_id(params)
    @thread = CfThread.includes(:messages).find_by_slug!(@id)

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

    @parent = @thread.find_message(params[:mid].to_i) if @thread

    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new(params[:cf_message])
    @message.parent_id  = @parent.message_id
    @message.forum_id   = current_forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.thread_id  = @thread.thread_id

    @message.created_at = DateTime.now
    @message.updated_at = DateTime.now

    @message.content    = content_to_internal(@message.content, uconf('quote_char', '> '))

    @preview = true if params[:preview]

    if not @preview and @message.save
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

  include AuthorizeForum
end

SettingValidator.validators['quote_old_message'] = lambda { |nam, val| %w{yes no}.include?(val) }

# eof
