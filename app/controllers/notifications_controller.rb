# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  before_filter :authorize!

  include AuthorizeUser

  def index
    @page  = params[:p].to_i
    @limit = uconf('pagination', 50).to_i

    @page  = 0 if @page < 0
    @limit = 50 if @limit <= 0

    @limit = 3

    @notifications = CfNotification.where(recipient_id: current_user.user_id).order('created_at DESC').limit(@limit).offset(@page * @limit).all
    @all_notifications_count = CfNotification.where(recipient_id: current_user.user_id).count

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
