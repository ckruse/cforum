# -*- coding: utf-8 -*-

class NotificationsPlugin < Plugin
  def created_new_message(thread, parent, message, tags)
    peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
  end

  def deleted_message(thread, message)
    CfNotification.delete_all(["oid = ? AND otype = 'message:create'", message.message_id])
  end

  def restored_message(thread, message)
    peon(class_name: 'NotifyNewTask', arguments: {type: 'message', thread: thread.thread_id, message: message.message_id})
  end

  def show_message(thread, message, votes)
    application_controller.notifications if check_for_deleting_notification(message)
  end

  def show_thread(thread, message = nil, votes = nil)
    had_one = false

    thread.sorted_messages.each do |m|
      had_one = true if check_for_deleting_notification(m)
    end

    application_controller.notifications if had_one
  end

  private
  def check_for_deleting_notification(message)
    if user = current_user
      if n = CfNotification.find_by_recipient_id_and_oid_and_otype_and_is_read(user.user_id, message.message_id, 'message:create', false)
        if uconf('delete_read_notifications', 'yes') == 'yes'
          n.destroy
        else
          n.is_read = true
          n.save!
        end

        return true
      end
    end

    return false
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
end

# eof
