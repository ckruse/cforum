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

      greeting  = user.conf('greeting')
      farewell  = user.conf('farewell')
      signature = user.conf('signature')

      msg.content = greeting + "\n" + msg.content unless greeting.blank?
      msg.content = msg.content + "\n" + farewell unless farewell.blank?
      msg.content = msg.content + "\n-- \n" + signature unless signature.blank?
    end
  end
end

notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, UserData.new(self))
notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, UserData.new(self))

# eof