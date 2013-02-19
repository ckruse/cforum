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

  def show
    @id = CfThread.make_id(params)

    conditions = {slug: @id}
    conditions[:messages] = {deleted: false} unless @view_all

    @thread = CfThread.preload(:messages => [:owner, :tags]).includes(:messages => :owner).where(conditions).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.nil?

    @parent = @message.parent_level

    if current_user
      if n = CfNotification.find_by_recipient_id_and_oid_and_otype_and_is_read(current_user.user_id, @message.message_id, 'message:create', false)
        @new_notifications -= [n]

        if uconf('delete_read_notifications', 'yes') == 'yes'
          n.destroy
        else
          n.is_read = true
          n.save!
        end
      end

      mids = @thread.messages.map {|m| m.message_id}
      votes = CfVote.where(user_id: current_user.user_id, message_id: mids).all
      @votes = {}

      votes.each do |v|
        @votes[v.message_id] = v
      end
    end

    if uconf('standard_view', 'thread-view') == 'thread-view'
      notification_center.notify(SHOW_MESSAGE, @thread, @message)
      render 'show-thread'
    else
      notification_center.notify(SHOW_THREAD, @thread, @message)
      render 'show-nested'
    end
  end

  def new
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:messages => [:owner, :tags]).includes(:messages).find_by_slug!(@id)
    raise CForum::ForbiddenException.new if @thread.archived and conf('use_archive') == 'yes'

    @parent = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new
    @tags    = @parent.tags.map {|t| t.tag_name}

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.content = @parent.to_quote if params.has_key?(:quote_old_message)

    notification_center.notify(SHOW_NEW_MESSAGE, @thread, @parent, @message)
  end

  def create
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:messages => [:owner, :tags]).includes(:messages).find_by_slug!(@id)
    raise CForum::ForbiddenException.new if @thread.archived and conf('use_archive') == 'yes'

    @parent = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    invalid = false

    @message = CfMessage.new(params[:cf_message])

    @message.parent_id  = @parent.message_id
    @message.forum_id   = current_forum.forum_id
    @message.user_id    = current_user.user_id unless current_user.blank?
    @message.thread_id  = @thread.thread_id

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
    retvals  = notification_center.notify(CREATING_NEW_MESSAGE, @thread, @parent, @message, @tags)

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
        save_tags(@message, @tags)

        saved = true
      end
    end

    if saved
      notification_center.notify(CREATED_NEW_MESSAGE, @thread, @parent, @message, @tags)
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

  def vote
    raise CForum::ForbiddenException.new if current_user.blank?

    @id      = CfThread.make_id(params)
    @thread  = CfThread.includes(:messages, :forum).find_by_slug!(@id)
    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.blank?

    if @message.user_id == current_user.user_id
      flash[:error] = t('messages.do_not_vote_yourself')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    vtype    = params[:type] == 'up' ? CfVote::UPVOTE : CfVote::DOWNVOTE

    if @vote = CfVote.find_by_user_id_and_message_id(current_user.user_id, @message.message_id) and @vote.vtype == vtype

      CfVote.transaction do
        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1 WHERE message_id = " + @message.message_id.to_s
        else
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes - 1 WHERE message_id = " + @message.message_id.to_s
        end

        CfScore.delete_all(['vote_id = ?', @vote.vote_id])
        @vote.destroy
      end

      # flash[:error] = t('messages.already_voted')
      redirect_to cf_message_url(@thread, @message), notice: t('messages.vote_removed')
      return
    end

    CfVote.transaction do
      if @vote
        @vote.update_attributes(vtype: vtype)

        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.delete_all(['user_id = ? AND vote_id = ?', current_user.user_id, @vote.vote_id])
            CfScore.update_all(['value = ?', Rails.application.config.vote_up_value], ['user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id])
          end
        else
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.update_all(['value = ?', -Rails.application.config.vote_down_value], ['user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id])
            CfScore.create!(user_id: current_user.user_id, vote_id: @vote.vote_id, value: -Rails.application.config.vote_down_value)
          end
        end

      else
        @vote = CfVote.create!(
          user_id: current_user.user_id,
          message_id: @message.message_id,
          vtype: vtype
        )

        unless @message.user_id.blank?
          CfScore.create!(
            user_id: @message.user_id,
            vote_id: @vote.vote_id,
            value: vtype == CfVote::UPVOTE ? Rails.application.config.vote_up_value : -Rails.application.config.vote_down_value
          )

          if vtype == CfVote::DOWNVOTE
            CfScore.create!(
              user_id: current_user.user_id,
              vote_id: @vote.vote_id,
              value: -Rails.application.config.vote_down_value
            )
          end
        end

        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s
        else
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s
        end
      end

    end

    flash[:notice] = t('messages.successfully_voted')
    redirect_to cf_message_url(@thread, @message)
  end

  def accept
    @id      = CfThread.make_id(params)
    @thread  = CfThread.includes(:messages, :forum).find_by_slug!(@id)
    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.blank?

    if @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    CfMessage.transaction do
      @message.accepted = !@message.accepted
      @message.save

      unless @message.user_id.blank?
        if @message.accepted
          @thread.messages.each do |m|
            if m.message_id != @message.message_id and m.accepted
              m.accepted = false
              m.save

              if not m.user_id.blank?
                scores = CfScore.where(user_id: m.user_id, message_id: m.message_id).all
                scores.each { |score| score.destroy } if not scores.blank?
              end
            end
          end

          CfScore.create!(
            user_id: @message.user_id,
            message_id: @message.message_id,
            value: Rails.application.config.accept_value
          )
        else
          scores = CfScore.where(user_id: @message.user_id, message_id: @message.message_id).all
          scores.each { |score| score.destroy } if not scores.blank?
        end
      end
    end

    redirect_to cf_message_url(@thread, @message), notice: @message.accepted ? t('messages.accepted') : t('messages.unaccepted')
  end

end

# eof
