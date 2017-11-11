class Messages::AcceptController < ApplicationController
  authorize_controller { authorize_forum(permission: :write?) }

  include SearchHelper

  def accept
    @thread, @message, @id = get_thread_w_post

    check_for_na && return
    check_for_access || return

    Message.transaction do
      @message.flags_will_change!

      if @message.flags['accepted'] == 'yes'
        @message.flags.delete('accepted')
        audit(@message, 'accepted-no')
      else
        @message.flags['accepted'] = 'yes'
        audit(@message, 'accepted-yes')
      end

      @message.save
      give_score
    end

    rescore_message(@message)

    type = @message.flags['accepted'] == 'yes' ? 'accepted' : 'unaccepted'
    VoteBadgeDistributorJob.perform_later(nil, @message.message_id, type)

    respond_to do |format|
      format.html do
        redirect_to message_url(@thread, @message), notice: (@message.flags['accepted'] == 'yes' ? t('messages.accepted') : t('messages.unaccepted'))
      end

      format.json do
        render json: { status: 'success', message: (@message.flags['accepted'] == 'yes' ? t('messages.accepted') : t('messages.unaccepted')) }
      end
    end
  end

  def check_for_na
    if (@message.flags['no-answer'] == 'yes') || (@message.flags['no-answer-admin'] == 'yes')
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.accepted_message_is_no_answer')
          redirect_to message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.accepted_message_is_no_answer') } }
      end

      return true
    end

    false
  end

  def check_for_access
    if @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to message_url(@thread, @message)
      return
    end

    unless may_answer(@message)
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to message_url(@thread, @message)
      return
    end

    true
  end

  def give_score
    if @message.user_id.present?

      if @message.flags['accepted'] == 'yes'
        score_val = conf('accept_value').to_i
        score_val = conf('accept_self_value').to_i if @message.user_id == current_user.try(:user_id)

        if score_val.to_i > 0
          scre = Score.create!(user_id: @message.user_id,
                               message_id: @message.message_id,
                               value: score_val)
          audit(scre, 'accepted-score')
        end

      else
        scores = Score.where(user_id: @message.user_id, message_id: @message.message_id)
        if scores.present?
          scores.each do |score|
            audit(score, 'accepted-no-unscore')
            score.destroy
          end
        end
      end

    end
  end
end

# eof
