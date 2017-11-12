class CloseVoteController < ApplicationController
  include CloseVoteHelper

  respond_to :html, :json

  authorize_controller { authorize_forum(permission: :write?) }

  authorize_action(%i[new create]) do
    current_user.present? &&
      (current_forum.moderator?(current_user) ||
       may?(Badge::CREATE_CLOSE_REOPEN_VOTE))
  end

  authorize_action(:vote) do
    current_user.present? &&
      (current_forum.moderator?(current_user) ||
       may?(Badge::VISIT_CLOSE_REOPEN))
  end

  def new
    @thread, @message, @id = get_thread_w_post

    if @message.close_vote.present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    @close_vote = CloseVote.new
    @close_vote.message_id = @message.message_id

    respond_with @close_vote
  end

  def new_open
    @thread, @message, @id = get_thread_w_post

    if @message.open_vote.present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.open_vote_already_exists')
      return
    end

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    @open_vote = CloseVote.new
    @open_vote.message_id = @message.message_id
    @open_vote.vote_type = true

    respond_with @open_vote
  end

  def create_open
    @thread, @message, @id = get_thread_w_post

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    if @message.open_vote.present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.open_vote_already_exists')
      return
    end

    do_create(true)
  end

  def create
    @thread, @message, @id = get_thread_w_post

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    if @message.close_vote.present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    do_create
  end

  def do_create(vtype = false)
    @close_vote = CloseVote.new(close_vote_params)
    @close_vote.message_id = @message.message_id
    @close_vote.vote_type = vtype

    if @close_vote.duplicate_slug.present? && @close_vote.duplicate_slug.match?(/^https?/)
      @close_vote.duplicate_slug = begin
                                     uri = URI.parse(@close_vote.duplicate_slug)
                                     # we have to remove the forum slug as well, thus the gsub
                                     uri.path.gsub(%r{^/[^/]+}, '')
                                   rescue URI::InvalidURIError
                                     nil
                                   end
    end

    saved = false
    CloseVote.transaction do
      if @close_vote.save
        saved = @close_vote.voters.create(user_id: current_user.user_id)
        audit(@close_vote, 'create')
      end

      raise ActiveRecord::Rollback unless saved
    end

    @open_vote = @close_vote if vtype

    respond_to do |format|
      if saved
        format.html do
          redirect_to message_url(@thread, @message),
                      notice: t('messages.close_vote.created')
        end
        format.json { render json: @close_vote }

        NotifyOpenCloseVoteJob.perform_later(@message.message_id, 'created', vtype)
      else
        format.html { render vtype ? :new_open : :new }
        format.json do
          render json: @close_vote.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def vote
    @thread, @message, @id = get_thread_w_post

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    do_vote(@message.close_vote)
  end

  def vote_open
    @thread, @message, @id = get_thread_w_post

    if @message.flags['no-answer-admin'].present?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.moderator_decision')
      return
    end

    do_vote(@message.open_vote)
  end

  def do_vote(vote)
    deleted = false

    if vote.blank?
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.no_vote')
      return
    end

    if vote.finished
      redirect_to message_url(@thread, @message),
                  notice: t('messages.close_vote.vote_already_closed')
      return
    end

    if vote.voted?(current_user)
      CloseVotesVoter.where(user_id: current_user.user_id,
                            close_vote_id: vote.close_vote_id)
        .first.destroy
      deleted = true
      vote.reload
    else
      unless vote.voters.create(user_id: current_user.user_id)
        redirect_to message_url(@thread, @message), notice: t('global.something_went_wrong')
        return
      end
    end

    if vote.voters.length >= conf('close_vote_votes').to_i
      Message.transaction do
        vote.update_attributes(finished: true)
        audit(vote, 'finished')

        if vote.vote_type == false
          finish_action_close(@message, vote)
        else
          finish_action_open(@message, vote)
        end
      end

      NotifyOpenCloseVoteJob.perform_later(@message.message_id, 'finished', vote.vote_type)
    end

    respond_to do |format|
      format.html do
        url = if @message.deleted
                forum_url(current_forum.slug)
              else
                message_url(@thread, @message)
              end

        redirect_to url,
                    notice: t(deleted ? 'messages.close_vote.vote_deleted' : 'messages.close_vote.voted')
      end
      format.json { render json: vote }
    end
  end

  private

  def finish_action_close(_msg, vote)
    action = vote_action(vote)

    if action == 'close'
      @message.flag_with_subtree('no-answer', 'yes')
      audit(@message, 'no-answer')
    else
      @message.delete_with_subtree
      audit(@message, 'delete')
    end
  end

  def finish_action_open(_msg, vote)
    action = vote_action(vote)

    if action == 'close'
      @message.del_flag_with_subtree('no-answer')
      audit(@message, 'no-answer-no')
    else
      @message.restore_with_subtree
      audit(@message, 'restore')
    end
  end

  def close_vote_params
    params.require(:close_vote)
      .permit(:reason, :duplicate_slug, :custom_reason)
  end
end

# eof
