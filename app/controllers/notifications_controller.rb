# -*- encoding: utf-8 -*-

class NotificationsController < ApplicationController
  authorize_controller { authorize_user }

  def index
    @limit = uconf('pagination').to_i
    @limit = 50 if @limit <= 0

    @notifications = CfNotification.where(recipient_id: current_user.user_id).
                     page(params[:page]).per(@limit)
    @notifications = sort_query(%w(created_at is_read subject),
                                @notifications)

    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def show
    @notification = CfNotification.where(recipient_id: current_user.user_id,
                                         notification_id: params[:id]).first!

    @notification.is_read = true
    @notification.save

    redirect_to @notification.path
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

  def last_changes
    if current_user.admin?
      @deleted_messages = CfMessage.
                          preload(:owner, :tags, votes: :voters, thread: :forum).
                          where(deleted: true).
                          order('updated_at DESC').
                          limit(10)

      @no_archive_threads = CfThread.
                            preload(:forum, messages: [:owner, :tags, votes: :voters]).
                            where("flags->'no-archive' = 'yes'").
                            order("updated_at DESC").
                            limit(10)

      @no_answer_messages = CfMessage.
                            preload(:owner, :tags, votes: :voters, thread: :forum).
                            where("flags->'no-answer-admin' = 'yes' OR flags->'no-answer' = 'yes'").
                            order("updated_at DESC").
                            limit(10)

      @images = Medium.
                order("created_at DESC").
                limit(10)

      @votes = CfCloseVote.
               preload(message: [:owner, :tags, {votes: :voters, thread: :forum}]).
               order("created_at DESC").
               limit(10)

      @flagged = CfMessage.
                 preload(:owner, :tags, votes: :voters, thread: :forum).
                 where("(flags->'flagged') IS NOT NULL").
                 order("created_at DESC").
                 limit(10)

      @new_users = CfUser.
                   order("created_at DESC").
                   limit(10)
    end

  end

end

# eof
