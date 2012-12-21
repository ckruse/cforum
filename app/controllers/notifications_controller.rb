# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  before_filter :authorize!

  include AuthorizeUser

  def index
    @notifications = CfNotification.order('created_at ASC').find_all_by_recipient_id(current_user.user_id)

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
