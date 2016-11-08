# -*- coding: utf-8 -*-

class Messages::SubscriptionsController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  def subscribe
    @thread, @message, = get_thread_w_post

    if previous_subscription?(@message)
      redirect_to(cf_return_url(@thread, @message),
                  notice: t('plugins.subscriptions.already_subscribed'))
      return
    end

    @subscription = Subscription.new(user_id: current_user.user_id,
                                     message_id: @message.message_id)

    respond_to do |format|
      if @subscription.save
        format.html do
          redirect_to(cf_return_url(@thread, @message),
                      notice: t('plugins.subscriptions.subscribed'))
        end
        format.json { render json: { status: :success, slug: @thread.slug } }
      else
        format.html do
          redirect_to(cf_return_url(@thread, @message),
                      notice: t('plugins.subscriptions.error_subscribing'))
        end
        format.json { render json: { status: :error, slug: @thread.slug } }
      end
    end
  end

  def unsubscribe
    @thread, @message, = get_thread_w_post

    @subscription = Subscription
                      .where(user_id: current_user.user_id,
                             message_id: @message.message_id)
                      .first!

    @subscription.destroy

    respond_to do |format|
      format.html do
        redirect_to(cf_return_url(@thread, @message),
                    notice: t('plugins.subscriptions.unsubscribed'))
      end
      format.json { render json: { status: :success, slug: @thread.slug } }
    end
  end

  private

  def previous_subscription?(message)
    message_ids = []

    parent = message.parent_level
    until parent.blank?
      message_ids << parent.message_id
      parent = parent.parent_level
    end

    return if message_ids.blank?

    Subscription
      .where(user_id: current_user.user_id,
             message_id: message_ids)
      .exists?
  end
end

# eof
