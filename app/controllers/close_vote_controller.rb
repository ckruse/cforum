class CloseVoteController < ApplicationController
  respond_to :html, :json

  before_filter :authorize!

  include AuthorizeForum

  authorize_action([:new, :create]) { not current_user.blank? and
    current_forum.moderator?(current_user) or
    may?(RIGHT_TO_CREATE_CLOSE_REOPEN_VOTES) }

  authorize_action(:vote) { not current_user.blank? and
    current_forum.moderator?(current_user) or
    may?(RIGHT_TO_VISIT_CLOSE_AND_REOPEN_VOTES) }

  def new
    @thread, @message, @id = get_thread_w_post

    if not @message.close_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    @close_vote =  CfCloseVote.new
    @close_vote.message_id = @message.message_id

    respond_with @close_vote
  end

  def create
    @thread, @message, @id = get_thread_w_post

    if not @message.close_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.close_vote_already_exists')
      return
    end

    @close_vote = CfCloseVote.new(close_vote_params)
    @close_vote.message_id = @message.message_id


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

    respond_to do |format|
      if saved
        format.html { redirect_to cf_message_url(@thread, @message),
          notice: t('messages.close_vote.created') }
        format.json { render json: @close_vote }
      else
        format.html { render :new }
        format.json { render json: @close_vote.errors,
          status: :unprocessable_entity }
      end
    end
  end

  def vote
    @thread, @message, @id = get_thread_w_post
    deleted = false

    if @message.close_vote.blank?
      redirect_to cf_message_url(@thread, @message),
        notice: t('messages.close_vote.no_close_vote')
      return
    end

    if @message.close_vote.has_voted?(current_user)
      CfCloseVotesVoter.where(user_id: current_user.user_id,
                              close_vote_id: @message.close_vote.close_vote_id).
        first.destroy
      deleted = true
    else
      if not @message.close_vote.voters.create(user_id: current_user.user_id)
        redirect_to cf_message_url(@thread, @message), notice: t('global.something_went_wrong')
        return
      end
    end


    respond_to do |format|
      format.html { redirect_to cf_message_url(@thread, @message),
        notice: t(deleted ? 'messages.close_vote.vote_deleted' : 'messages.close_vote.voted') }
      format.json { render json: @close_vote }
    end
  end

  private

  def close_vote_params
    params.require(:cf_close_vote).
      permit(:reason, :duplicate_slug, :custom_reason)
  end
end
