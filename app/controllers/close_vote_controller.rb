# -*- coding: utf-8 -*-

class CloseVoteController < ApplicationController
  respond_to :html, :json

  before_filter :authorize!

  include AuthorizeForum

  authorize_action([:new, :create]) { not current_user.blank? and
    (current_forum.moderator?(current_user) or
     may?(CREATE_CLOSE_REOPEN_VOTE)) }

  authorize_action(:vote) { not current_user.blank? and
    (current_forum.moderator?(current_user) or
     may?(VISIT_CLOSE_REOPEN)) }

  def new
    @thread, @message, @id = get_thread_w_post

    if not @message.close_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    @close_vote =  CfCloseVote.new
    @close_vote.message_id = @message.message_id

    respond_with @close_vote
  end

  def new_open
    @thread, @message, @id = get_thread_w_post

    if not @message.open_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.open_vote_already_exists')
      return
    end

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    @open_vote =  CfCloseVote.new
    @open_vote.message_id = @message.message_id
    @open_vote.vote_type = true

    respond_with @open_vote
  end

  def create_open
    @thread, @message, @id = get_thread_w_post

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    if not @message.open_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.open_vote_already_exists')
      return
    end

    do_create(true)
  end

  def create
    @thread, @message, @id = get_thread_w_post

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    if not @message.close_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    do_create
  end

  def do_create(vtype = false)
    @close_vote = CfCloseVote.new(close_vote_params)
    @close_vote.message_id = @message.message_id
    @close_vote.vote_type = vtype

    if not @close_vote.duplicate_slug.blank? and
        @close_vote.duplicate_slug =~ /^https?/
      begin
        uri = URI.parse(@close_vote.duplicate_slug)
        # we have to remove the forum slug as well, thus the gsub
        @close_vote.duplicate_slug = uri.path.gsub(/^\/[^\/]+/, '')
      rescue
      end
    end

    saved = false
    CfCloseVote.transaction do
      if @close_vote.save
        saved = @close_vote.voters.create(user_id: current_user.user_id)
      end

      raise ActiveRecord::Rollback unless saved
    end

    @open_vote = @close_vote if vtype

    respond_to do |format|
      if saved
        format.html { redirect_to cf_message_url(@thread, @message),
          notice: t('messages.close_vote.created') }
        format.json { render json: @close_vote }
      else
        format.html { render vtype ? :new_open : :new }
        format.json { render json: @close_vote.errors,
          status: :unprocessable_entity }
      end
    end
  end

  def vote
    @thread, @message, @id = get_thread_w_post

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    do_vote(@message.close_vote)
  end

  def vote_open
    @thread, @message, @id = get_thread_w_post

    if not @message.flags['no-answer-admin'].blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.moderator_decision')
      return
    end

    do_vote(@message.open_vote)
  end

  def do_vote(vote)
    deleted = false

    if vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.no_vote')
      return
    end

    if vote.finished
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.vote_already_closed')
      return
    end

    if vote.has_voted?(current_user)
      CfCloseVotesVoter.where(user_id: current_user.user_id,
                              close_vote_id: vote.close_vote_id).
        first.destroy
      deleted = true
    else
      if not vote.voters.create(user_id: current_user.user_id)
        redirect_to cf_message_url(@thread, @message), notice: t('global.something_went_wrong')
        return
      end
    end

    if vote.voters.length >= conf("close_vote_votes", 5).to_i
      CfMessage.transaction do
        vote.update_attributes(finished: true)

        if vote.vote_type == false
          @message.flag_with_subtree('no-answer', 'yes')
        else
          @message.del_flag_with_subtree('no-answer')
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message),
        notice: t(deleted ? 'messages.close_vote.vote_deleted' : 'messages.close_vote.voted') }
      format.json { render json: vote }
    end
  end

  private

  def close_vote_params
    params.require(:cf_close_vote).
      permit(:reason, :duplicate_slug, :custom_reason)
  end
end
