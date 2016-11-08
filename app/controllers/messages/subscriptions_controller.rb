# -*- coding: utf-8 -*-

class Messages::SubscriptionsController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  def subscribe
    @thread, @message, _ = get_thread_w_post

    @subscription = Subscription.new(user_id: current_user.user_id,
                                     message_id: @message.message_id)

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to cf_return_url(@thread, @message), notice: t('plugins.subscriptions.subscribed') }
        format.json { render json: { status: :success, slug: @thread.slug } }
      else
        format.html { redirect_to cf_return_url(@thread, @message), notice: t('plugins.subscriptions.error_subscribing') }
        format.json { render json: { status: :error, slug: @thread.slug } }
      end
    end
  end

  def unsubscribe
    @thread, @message, _ = get_thread_w_post

    @subscription = Subscription.
                      where(user_id: current_user.user_id,
                            message_id: @message.message_id).
                      first!

    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message),
                                notice: t('plugins.subscriptions.unsubscribed') }
      format.json { render json: {status: :success, slug: @thread.slug } }
    end
  end
end

# eof
