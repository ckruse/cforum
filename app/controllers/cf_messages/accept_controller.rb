# -*- coding: utf-8 -*-

class CfMessages::AcceptController < ApplicationController
  authorize_controller { authorize_forum(permission: :write?) }

  ACCEPTING_MESSAGE    = "accepting_message"
  ACCEPTED_MESSAGE     = "accepted_message"

  def accept
    @thread, @message, @id = get_thread_w_post

    check_for_na and return
    check_for_access or return

    notification_center.notify(ACCEPTING_MESSAGE, @thread, @message)
    CfMessage.transaction do
      @message.flags_will_change!

      if @message.flags['accepted'] == 'yes'
        @message.flags.delete('accepted')
      else
        @message.flags['accepted'] = 'yes'
      end

      @message.save
      give_score
    end
    notification_center.notify(ACCEPTED_MESSAGE, @thread, @message)

    redirect_to cf_message_url(@thread, @message), notice: (@message.flags['accepted'] == 'yes' ? t('messages.accepted') : t('messages.unaccepted'))
  end

  def check_for_na
    if @message.flags["no-answer"] == 'yes' or @message.flags['no-answer-admin'] == 'yes'
      respond_to do |format|
        format.html do
          flash[:error] = t('messages.accepted_message_is_no_answer')
          redirect_to cf_message_url(@thread, @message)
        end

        format.json { render json: { status: 'error', message: t('messages.accepted_message_is_no_answer') } }
      end

      return true
    end

    return false
  end

  def check_for_access
    if @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    if not may_answer(@message)
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    return true
  end

  def give_score
    unless @message.user_id.blank?
      if @message.flags['accepted'] == 'yes'
        CfScore.create!(
          user_id: @message.user_id,
          message_id: @message.message_id,
          value: conf('accept_value').to_i
        )
      else
        scores = CfScore.where(user_id: @message.user_id, message_id: @message.message_id)
        scores.each { |score| score.destroy } if not scores.blank?
      end
    end
  end
end

# eof
