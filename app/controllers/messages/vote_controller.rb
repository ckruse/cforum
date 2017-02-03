# -*- coding: utf-8 -*-

class Messages::VoteController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :write?) }

  include SearchHelper

  # TODO: votable with anoynmous user
  def vote
    raise CForum::ForbiddenException.new if current_user.blank?

    @thread, @message, @id = get_thread_w_post

    check_for_access or return

    @vote_down_value = conf('vote_down_value').to_i

    # we may use a different vote_up_value if user is the author of the OP
    @vote_up_value = conf('vote_up_value').to_i
    @vote_up_value = conf('vote_up_value_user').to_i unless @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])

    vtype    = params[:type] == 'up' ? Vote::UPVOTE : Vote::DOWNVOTE

    if params[:type] == 'up'
      vtype = Vote::UPVOTE
      check_if_user_may(Badge::UPVOTE, 'messages.insufficient_rights_to_upvote') or return
    else
      vtype = Vote::DOWNVOTE
      check_if_user_may(Badge::DOWNVOTE, 'messages.insufficient_rights_to_downvote') or return
    end

    # remove voting if user already voted with the same parameters
    maybe_take_back_vote(vtype) and return

    check_for_downvote_score(vtype) or return

    Vote.transaction do
      if @vote
        update_existing_vote(vtype)
      else
        create_new_vote(vtype)
      end
    end

    rescore_message(@message)

    respond_to do |format|
      format.html do
        flash[:notice] = t('messages.successfully_voted')
        redirect_to message_url(@thread, @message)
      end

      format.json do
        @message.reload
        render json: { status: 'success', score: @message.score_str, message: t('messages.successfully_voted') }
      end
    end
  end

  def check_for_access
    if @message.user_id == current_user.user_id
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.do_not_vote_yourself')
          redirect_to message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.do_not_vote_yourself') } }
      end

      return
    end

    if @message.flags["no-answer"] == 'yes' or @message.flags['no-answer-admin'] == 'yes'
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.message_is_no_answer')
          redirect_to message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.message_is_no_answer') } }
      end

      return
    end

    return true
  end

  def check_if_user_may(right, msg)
    unless may?(right)
      respond_to do |format|
        format.html do
          flash[:error] = t(msg)
          redirect_to message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: msg } }
      end

      return
    end

    return true
  end

  def check_for_downvote_score(vtype)
    if current_user.score <= 0 and vtype == Vote::DOWNVOTE
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.not_enough_score')
          redirect_to message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.not_enough_score') } }
      end

      return
    end

    return true
  end

  def maybe_take_back_vote(vtype)
    @vote = Vote.where(user_id: current_user.user_id, message_id: @message.message_id).first

    if not @vote.blank? and @vote.vtype == vtype
      Vote.transaction do
        if @vote.vtype == Vote::UPVOTE
          Vote.connection.execute "UPDATE messages SET upvotes = upvotes - 1 WHERE message_id = " + @message.message_id.to_s
        else
          Vote.connection.execute "UPDATE messages SET downvotes = downvotes - 1 WHERE message_id = " + @message.message_id.to_s
        end

        Score.where('vote_id = ?', @vote.vote_id).delete_all
        @vote.destroy
      end

      rescore_message(@message)

      respond_to do |format|
        format.html { redirect_to message_url(@thread, @message), notice: t('messages.vote_removed') }
        format.json do
          @message.reload
          render json: { status: 'success', score: @message.score_str, message: t('messages.vote_removed') }
        end
      end

      return true
    end

    return
  end

  def update_existing_vote(vtype)
    @vote.update_attributes(vtype: vtype)

    if @vote.vtype == Vote::UPVOTE
      Vote.connection.execute "UPDATE messages SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s

      Score.delete_all(['user_id = ? AND vote_id = ?', current_user.user_id, @vote.vote_id])
      unless @message.user_id.blank?
        Score.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).update_all(['value = ?', @vote_up_value])
      end

      peon(class_name: 'BadgeDistributor',
           arguments: {type: 'changed-vote',
                       vote_id: @vote.vote_id,
                       message_id: @message.message_id})
    else
      Vote.connection.execute "UPDATE messages SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s

      unless @message.user_id.blank?
        Score.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).delete_all

        if @message.owner.score + @vote_down_value >= -1
          Score.create!(
            user_id: @message.user_id,
            vote_id: @vote.vote_id,
            value: vtype == Vote::UPVOTE ? @vote_up_value : @vote_down_value
          )
        else
          Score.create!(
            user_id: @message.user_id,
            vote_id: @vote.vote_id,
            value: -1 - @message.owner.score
          )
        end
      end

      Score.create!(user_id: current_user.user_id, vote_id: @vote.vote_id, value: @vote_down_value)
    end
  end

  def create_new_vote(vtype)
    @vote = Vote.create!(
      user_id: current_user.user_id,
      message_id: @message.message_id,
      vtype: vtype
    )

    unless @message.user_id.blank?
      if (vtype == Vote::DOWNVOTE and @message.owner.score + @vote_down_value >= -1) or vtype == Vote::UPVOTE
        Score.create!(
          user_id: @message.user_id,
          vote_id: @vote.vote_id,
          value: vtype == Vote::UPVOTE ? @vote_up_value : @vote_down_value
        )
      elsif vtype == Vote::DOWNVOTE and @message.owner.score + @vote_down_value < -1
        Score.create!(
          user_id: @message.user_id,
          vote_id: @vote.vote_id,
          value: -1 - @message.owner.score
        )
      end
    end

    if vtype == Vote::DOWNVOTE
      Score.create!(
        user_id: current_user.user_id,
        vote_id: @vote.vote_id,
        value: @vote_down_value
      )
    end

    if @vote.vtype == Vote::UPVOTE
      Vote.connection.execute "UPDATE messages SET upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s
    else
      Vote.connection.execute "UPDATE messages SET downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s
    end

    peon(class_name: 'BadgeDistributor',
         arguments: {type: 'voted',
                     message_id: @message.message_id,
                     vote_id: @vote.vote_id})
  end

end

# eof
