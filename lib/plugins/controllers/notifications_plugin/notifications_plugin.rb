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
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  notifications_plugin = NotificationsPlugin.new(app_controller)

  app_controller.notification_center.register_hook(CfMessagesController::CREATED_NEW_MESSAGE, notifications_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::DELETED_MESSAGE, notifications_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::RESTORED_MESSAGE, notifications_plugin)
end

# eof
