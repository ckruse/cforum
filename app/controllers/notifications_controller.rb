# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  authorize_controller { authorize_user }

  def index
    @limit = uconf('pagination').to_i
    @limit = 50 if @limit <= 0

    @notifications = CfNotification.where(recipient_id: current_user.user_id).
                     page(params[:p]).per(@limit)
    @notifications = sort_query(%w(created_at is_read subject),
                                @notifications)

    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def update
    @notification = CfNotification.where(recipient_id: current_user.user_id,
                                         notification_id: params[:id]).first!

    respond_to do |format|
      if @notification.update_attributes(is_read: false)
        format.html { redirect_to notifications_path,
          notice: t('notifications.marked_unread') }
        format.json { render json: @notification }

      else
        format.html { redirect_to notifications_path,
          notice: t('global.something_went_wrong') }
        format.json { render json: n.errors, status: :unprocessable_entity }
      end
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
