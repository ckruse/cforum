# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  before_filter :authorize!

  include AuthorizeUser

  def index
    @notifications = CfNotification.where(recipient_id: current_user.user_id).order('created_at DESC').limit(10).all

    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def destroy
    @notification = CfNotification.find_by_recipient_id_and_notification_id!(current_user.user_id, params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url, notice: t('notifications.destroyed') }
      format.json { head :no_content }
    end
  end

end

# eof
