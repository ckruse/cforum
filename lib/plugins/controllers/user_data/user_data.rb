# -*- coding: utf-8 -*-

class UserDataPlugin < Plugin
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

      msg.content  ||= ""

      greeting  = user.conf('greeting')
      farewell  = user.conf('farewell')
      signature = user.conf('signature')

      msg.content = greeting + "\n" + msg.content unless greeting.blank?
      msg.content = msg.content + "\n" + farewell unless farewell.blank?
      msg.content = msg.content + "\n-- \n" + signature unless signature.blank?
    end
  end

  def saving_settings(user, settings)
    if user.conf('secured_name', 'no') == 'no' and settings.options['secured_name'] == 'yes'
      sn = SecuredName.find_by_name settings.options['name']
      existing = Settings.find_by_user_id user.user_id

      if sn.blank?
        SecuredName.transaction do
          if existing
            existing.name = settings.options['name']
            existing.save
          else
            SecuredName.create!(:user_id => user.user_id, name: settings.options['name'])
          end
        end

        return
      elsif sn.user_id == user.user_id
        return
      end

      raise ActiveRecord::Rollback.new
    end

  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  ud_plugin = UserDataPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, ud_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, ud_plugin)

  #app_controller.notification_center.register_hook(UsersController::SHOWING_SETTINGS, ud_plugin)
  app_controller.notification_center.register_hook(UsersController::SAVING_SETTINGS, ud_plugin)
end

# eof
