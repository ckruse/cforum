# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  before_filter :authorize!

  include AuthorizeUser

  def index
    @limit = uconf('pagination', 50).to_i
    @limit = 50 if @limit <= 0

    @notifications = CfNotification.where(recipient_id: current_user.user_id).
      order('created_at DESC').page(params[:p]).per(@limit)
    @all_notifications_count = CfNotification.
      where(recipient_id: current_user.user_id).count

    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def batch_destroy
    unless params[:ids].blank?
      CfNotification.transaction do
        @notifications = CfNotification.where(recipient_id: current_user.user_id, notification_id: params[:ids])
        @notifications.each do |n|
          n.destroy
        end
      end
    end

    redirect_to notifications_url, notice: t('notifications.destroyed')
  end

  def destroy
    @notification = CfNotification.where(recipient_id: current_user.user_id, notification_id: params[:id]).first!
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url, notice: t('notifications.destroyed') }
      format.json { head :no_content }
    end
  end

end

# eof
