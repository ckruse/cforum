# -*- coding: utf-8 -*-

class FlattrPlugin < Plugin
  def creating_new_message(thread, parent, message, tags)
    flattr_id = uconf('flattr')
    message.flags['flattr_id'] = flattr_id if not flattr_id.blank?
    return true
  end

  def new_thread(thread, message, tags)
    return creating_new_message(thread, nil, message, tags)
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  flattr_plugin = FlattrPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfMessagesController::CREATING_NEW_MESSAGE, flattr_plugin)
  app_controller.notification_center.
    register_hook(CfThreadsController::NEW_THREAD, flattr_plugin)
end


# eof
