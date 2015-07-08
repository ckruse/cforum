# -*- coding: utf-8 -*-

class VotePluginController < ApplicationController
  VOTING_MESSAGE       = "voting_message"
  VOTED_MESSAGE        = "voted_message"

  UNVOTING_MESSAGE     = "unvoting_message"
  UNVOTED_MESSAGE      = "unvoted_message"

  authorize_controller { authorize_user && authorize_forum(permission: :write?) }

  # TODO: votable with anoynmous user
  def vote
    raise CForum::ForbiddenException.new if current_user.blank?

    @thread, @message, @id = get_thread_w_post

    if @message.user_id == current_user.user_id
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.do_not_vote_yourself')
          redirect_to cf_message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.do_not_vote_yourself') } }
      end

      return
    end

    if @message.flags["no-answer"] == 'yes' or @message.flags['no-answer-admin'] == 'yes'
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.message_is_no_answer')
          redirect_to cf_message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.message_is_no_answer') } }
      end

      return
    end

    vote_down_value = conf('vote_down_value').to_i

    # we may use a different vote_up_value if user is the author of the OP
    vote_up_value = conf('vote_up_value').to_i
    vote_up_value = conf('vote_up_value_user').to_i unless @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])

    vtype    = params[:type] == 'up' ? CfVote::UPVOTE : CfVote::DOWNVOTE

    if params[:type] == 'up'
      vtype = CfVote::UPVOTE

      unless may?(RightsHelper::UPVOTE)
        respond_to do |format|
          format.html do
            flash[:error] = t('messages.insufficient_rights_to_upvote')
            redirect_to cf_message_url(@thread, @message)
          end

          format.json { render json: { status: 'error', message: t('messages.insufficient_rights_to_upvote') } }
        end

        return
      end
    else
      vtype = CfVote::DOWNVOTE

      unless may?(RightsHelper::DOWNVOTE)
        respond_to do |format|
          format.html do
            flash[:error] = t('messages.insufficient_rights_to_downvote')
            redirect_to cf_message_url(@thread, @message)
          end

          format.json { render json: { status: 'error', message: t('messages.insufficient_rights_to_downvote') } }
        end

        return
      end
    end

    # remove voting if user already voted with the same parameters
    if @vote = CfVote.where(user_id: current_user.user_id, message_id: @message.message_id).first and @vote.vtype == vtype
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

      respond_to do |format|
        format.html { redirect_to cf_message_url(@thread, @message), notice: t('messages.vote_removed') }
        format.json do
          @message.reload
          render json: { status: 'success', score: @message.score_str, message: t('messages.vote_removed') }
        end
      end

      return
    end

    if current_user.score <= 0 and vtype == CfVote::DOWNVOTE
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.not_enough_score')
          redirect_to cf_message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.not_enough_score') } }
      end

      return
    end

    notification_center.notify(VOTING_MESSAGE, @message)
    CfVote.transaction do
      if @vote
        @vote.update_attributes(vtype: vtype)

        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s

          CfScore.delete_all(['user_id = ? AND vote_id = ?', current_user.user_id, @vote.vote_id])
          unless @message.user_id.blank?
            CfScore.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).update_all(['value = ?', vote_up_value])
          end

          peon(class_name: 'BadgeDistributor',
               arguments: {type: 'changed-vote',
                           message_id: @message.message_id})
        else
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).update_all(['value = ?', vote_down_value])
          end

          CfScore.create!(user_id: current_user.user_id, vote_id: @vote.vote_id, value: vote_down_value)
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
        end

        if vtype == CfVote::DOWNVOTE
          CfScore.create!(
            user_id: current_user.user_id,
            vote_id: @vote.vote_id,
            value: vote_down_value
          )
        end

        if @vote.vtype == CfVote::UPVOTE
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes + 1 WHERE message_id = " + @message.message_id.to_s
        else
          CfVote.connection.execute "UPDATE messages SET downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s
        end

        peon(class_name: 'BadgeDistributor',
             arguments: {type: 'voted',
                         message_id: @message.message_id})
      end

    end
    notification_center.notify(VOTED_MESSAGE, @message)

    respond_to do |format|
      format.html do
        flash[:notice] = t('messages.successfully_voted')
        redirect_to cf_message_url(@thread, @message)
      end

      format.json do
        @message.reload
        render json: { status: 'success', score: @message.score_str, message: t('messages.successfully_voted') }
      end
    end
  end
end

# eof
