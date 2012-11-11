# -*- coding: utf-8 -*-

class UserData < Plugin
  def show_new_thread(thread, params)
    set_vars(thread.message, params)
  end

  def show_new_message(thread, message, params)
    set_vars(message, params)
  end

  def set_vars(msg, params)
    if user = current_user
      settings = ConfigManager.setting(user, current_forum)

      msg.author   ||= settings['name']
      msg.email    ||= settings['email']
      msg.homepage ||= settings['homepage']
    end
  end
end

notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, UserData.new(self))
notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, UserData.new(self))

# eof