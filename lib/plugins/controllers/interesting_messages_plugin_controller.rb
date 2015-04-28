# -*- coding: utf-8 -*-

class InterestingMessagesPluginController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  SHOW_INTERESTING_MESSAGELIST = "show_interesting_messagelist"

  def mark_interesting
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return :redirected
    end

    @thread, @message, @id = get_thread_w_post

    begin
      CfInterestingMessage.create!(message_id: @message.message_id,
                                   user_id: current_user.user_id)
    rescue ActiveRecord::RecordNotUnique
    end

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message),
                                notice: t('plugins.interesting_messages.marked_interesting') }
      format.json { render json: {status: :success, location: cf_thread_url(@thread) } }
    end
  end

  def mark_boring
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return :redirected
    end

    @thread, @message, @id = get_thread_w_post

    im = CfInterestingMessage.where(message_id: @message.message_id,
                                    user_id: current_user.user_id).first!

    im.destroy

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message),
                                notice: t('plugins.interesting_messages.unmarked_interesting') }
      format.json { render json: {status: :success, location: cf_thread_url(@thread) } }
    end
  end

  def list_messages
    @limit = conf('pagination').to_i

    @messages = CfMessage.
      preload(:thread, :forum, :tags, {votes: :voters}).
      joins('INNER JOIN interesting_messages USING(message_id)').
      where('interesting_messages.user_id = ?', current_user.user_id).
      order(:created_at).page(params[:p]).per(@limit)

    ret = notification_center.notify(SHOW_INTERESTING_MESSAGELIST, @messages)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render @messages }
      end
    end
  end
end


# eof
