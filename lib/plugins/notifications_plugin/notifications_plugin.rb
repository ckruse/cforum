# -*- coding: utf-8 -*-

class NotificationsPlugin < Plugin
  def created_new_message(thread, parent, message, tags)
    peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
  end

  def new_thread_saved(thread, message)
    peon(class_name: 'NotifyNewTask', arguments: {type: 'thread', thread: thread.thread_id, message: message.message_id})
  end

  def thread_moved(thread, old_forum, new_forum)
    peon(class_name: 'ThreadMovedTask', arguments: {thread: thread.thread_id, old_forum: old_forum.forum_id, new_forum: new_forum.forum_id})
  end

  def deleted_message(thread, message)
    CfNotification.
      delete_all(["oid = ? AND otype IN ('message:create-answer', 'message:create-activity')",
                  message.message_id])
  end

  def restored_message(thread, message)
    peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
  end

  def show_message(thread, message, votes)
    application_controller.notifications if check_for_deleting_notification(thread, message)
  end

  def show_thread(thread, message = nil, votes = nil)
    return if current_user.blank?

    had_one = false
    message_ids = thread.messages.map { |m| m.message_id }

    if user = current_user
      to_delete = []
      to_mark_read = []
      notifications = CfNotification.
                      where(recipient_id: user.user_id,
                            oid: message_ids).
                      where("otype IN ('message:create-answer','message:create-activity', 'message:mention')").
                      all

      notifications.each do |n|
        had_one = true

        if (n.otype == 'message:create-answer' and
            uconf('delete_read_notifications_on_answer') == 'yes') or
          (n.otype == 'message:create-activity' and
           uconf('delete_read_notifications_on_activity') == 'yes') or
          (n.otype == 'message:mention' and
           uconf('delete_read_notifications_on_mention') == 'yes')
          to_delete << n.notification_id
        else
          to_mark_read << n.notification_id
        end
      end

      CfNotification.where(notification_id: to_delete).delete_all unless to_delete.blank?
      CfNotification.where(notification_id: to_mark_read).update_all(is_read: true) unless to_mark_read.blank?
    end

    application_controller.notifications if had_one
  end

  def show_badge(badge)
    return if current_user.blank?

    had_one = false
    notifications = CfNotification.where(otype: 'badge',
                                         oid: badge.badge_id,
                                         recipient_id: current_user.user_id,
                                         is_read: false).all

    notifications.each do |n|
      n.is_read = true
      n.save

      had_one = true
    end

    application_controller.notifications if had_one
  end

  private
  def check_for_deleting_notification(thread, message)
    had_one = false

    if user = current_user
      n = CfNotification.
        where(recipient_id: user.user_id,
              oid: message.message_id).
        where("otype IN ('message:create-answer','message:create-activity', 'message:mention')").
        first

      unless n.blank?
        had_one = true

        if (n.otype == 'message:create-answer' and
            uconf('delete_read_notifications_on_answer') == 'yes') or
          (n.otype == 'message:create-activity' and
           uconf('delete_read_notifications_on_activity') == 'yes') or
          (n.otype == 'message:mention' and
           uconf('delete_read_notifications_on_mention') == 'yes')
          n.destroy
        else
          n.is_read = true
          n.save!
        end
      end

      n = CfNotification.
          where(recipient_id: user.user_id,
                oid: thread.thread_id,
                is_read: false).
          where("otype IN ('thread:moved')").
          first

      unless n.blank?
        had_one = true
        n.is_read = true
        n.save!
      end
    end

    return had_one
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  notifications_plugin = NotificationsPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfMessagesController::CREATED_NEW_MESSAGE, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::DELETED_MESSAGE, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::RESTORED_MESSAGE, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, notifications_plugin)
  app_controller.notification_center.
    register_hook(BadgesController::SHOW_BADGE, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfThreadsController::THREAD_MOVED, notifications_plugin)
  app_controller.notification_center.
    register_hook(CfThreadsController::NEW_THREAD_SAVED, notifications_plugin)
end

# eof
