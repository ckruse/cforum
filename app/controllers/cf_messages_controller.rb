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

  DELETING_MESSAGE     = "deleting_message"
  DELETED_MESSAGE      = "deleted_message"

  RESTORING_MESSAGE    = "restoring_message"
  RESTORED_MESSAGE     = "restored_message"

  VOTING_MESSAGE       = "voting_message"
  VOTED_MESSAGE        = "voted_message"

  UNVOTING_MESSAGE     = "unvoting_message"
  UNVOTED_MESSAGE      = "unvoted_message"

  ACCEPTING_MESSAGE    = "accepting_message"
  ACCEPTED_MESSAGE     = "accepted_message"

  def show
    get_thread_w_post

    @parent = @message.parent_level

    if current_user
      mids = @thread.messages.map {|m| m.message_id}
      votes = CfVote.where(user_id: current_user.user_id, message_id: mids).all
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

  def new
    get_thread_w_post

    @parent  = @message
    @message = CfMessage.new
    @tags    = @parent.tags.map {|t| t.tag_name}

    @max_tags = conf('max_tags_per_message', 3)

    # inherit message and subject from previous post
    @message.subject = @parent.subject
    @message.content = @parent.to_quote if params.has_key?(:quote_old_message)

    notification_center.notify(SHOW_NEW_MESSAGE, @thread, @parent, @message)
  end

  def create
    get_thread_w_post

    invalid  = false

    @parent  = @message
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
      notification_center.notify(CREATED_NEW_MESSAGE, @thread, @parent, @message, @tags)
      redirect_to cf_message_path(@thread, @message), :notice => I18n.t('messages.created')
    else
      render :new
    end
  end

  def destroy
    get_thread_w_post

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
    get_thread_w_post

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

  # TODO: votable with anoynmous user
  def vote
    raise CForum::ForbiddenException.new if current_user.blank?

    get_thread_w_post

    if @message.user_id == current_user.user_id
      flash[:error] = t('messages.do_not_vote_yourself')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    vote_down_value = conf('vote_down_value', -1).to_i

    # we may use a different vote_up_value if user is the author of the OP
    vote_up_value = conf('vote_up_value', 10).to_i
    vote_up_value = conf('vote_up_value_user', 10).to_i unless @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])

    vtype    = params[:type] == 'up' ? CfVote::UPVOTE : CfVote::DOWNVOTE

    # remove voting if user already voted with the same parameters
    if @vote = CfVote.find_by_user_id_and_message_id(current_user.user_id, @message.message_id) and @vote.vtype == vtype

      notification_center.notify(UNVOTING_MESSAGE, @message, @vote)
      CfVote.transaction do
        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1 WHERE message_id = " + @message.message_id.to_s
        else
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes - 1 WHERE message_id = " + @message.message_id.to_s
        end

        CfScore.delete_all(['vote_id = ?', @vote.vote_id])
        @vote.destroy
      end
      notification_center.notify(UNVOTED_MESSAGE, @message, @vote)

      # flash[:error] = t('messages.already_voted')
      redirect_to cf_message_url(@thread, @message), notice: t('messages.vote_removed')
      return
    end

    notification_center.notify(VOTING_MESSAGE, @message)
    CfVote.transaction do
      if @vote
        @vote.update_attributes(vtype: vtype)

        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.delete_all(['user_id = ? AND vote_id = ?', current_user.user_id, @vote.vote_id])
            CfScore.update_all(['value = ?', vote_up_value], ['user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id])
          end
        else
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.update_all(['value = ?', vote_down_value], ['user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id])
            CfScore.create!(user_id: current_user.user_id, vote_id: @vote.vote_id, value: vote_down_value)
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
            value: vtype == CfVote::UPVOTE ? vote_up_value : vote_down_value
          )

          if vtype == CfVote::DOWNVOTE
            CfScore.create!(
              user_id: current_user.user_id,
              vote_id: @vote.vote_id,
              value: vote_down_value
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
    notification_center.notify(VOTED_MESSAGE, @message)

    flash[:notice] = t('messages.successfully_voted')
    redirect_to cf_message_url(@thread, @message)
  end

  def accept
    get_thread_w_post

    if @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    notification_center.notify(ACCEPTING_MESSAGE, @thread, @message)
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
            value: conf('accept_value', 15).to_i
          )
        else
          scores = CfScore.where(user_id: @message.user_id, message_id: @message.message_id).all
          scores.each { |score| score.destroy } if not scores.blank?
        end
      end
    end
    notification_center.notify(ACCEPTED_MESSAGE, @thread, @message)

    redirect_to cf_message_url(@thread, @message), notice: @message.accepted ? t('messages.accepted') : t('messages.unaccepted')
  end


  private

  def get_thread_w_post
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:forum, :messages => [:owner, :tags]).includes(:messages => :owner).where(std_conditions(@id)).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.nil?
  end
end

# eof
