# -*- coding: utf-8 -*-

class UserData < Plugin
  def show_new_thread(thread)
    set_vars(thread.message)
  end

  def show_new_message(thread, message)
    set_vars(message)
  end

  def set_vars(msg)
    if user = current_user
      msg.author   ||= user.conf('name')
      msg.email    ||= user.conf('email')
      msg.homepage ||= user.conf('url')
    end
  end
end

notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, UserData.new(self))
notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, UserData.new(self))

# eof