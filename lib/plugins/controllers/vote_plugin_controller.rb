# -*- coding: utf-8 -*-

class VotePluginController < ApplicationController
  VOTING_MESSAGE       = "voting_message"
  VOTED_MESSAGE        = "voted_message"

  UNVOTING_MESSAGE     = "unvoting_message"
  UNVOTED_MESSAGE      = "unvoted_message"

  # TODO: votable with anoynmous user
  def vote
    raise CForum::ForbiddenException.new if current_user.blank?

    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:forum, :messages => [:owner, :tags]).includes(:messages => :owner).where(std_conditions(@id)).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.nil?

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
            CfScore.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).update_all(['value = ?', vote_up_value])
          end
        else
          CfVote.connection.execute "UPDATE messages SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE message_id = " + @message.message_id.to_s

          unless @message.user_id.blank?
            CfScore.where('user_id = ? AND vote_id = ?', @message.user_id, @vote.vote_id).update_all(['value = ?', vote_down_value])
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
end

# eof
