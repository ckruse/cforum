# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), 'secured_name.rb')

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
    if settings.options['secured_name'] == 'yes' and not settings.options['name'].blank?
      nam = settings.options['name'].strip.downcase

      sn = SecuredName.where('name = LOWER(?)', nam).first
      existing = SecuredName.find_by_user_id user.user_id

      if sn.blank?
        SecuredName.transaction do
          if existing
            existing.name = nam
            existing.save
          else
            SecuredName.create!(:user_id => user.user_id, name: nam)
          end
        end

        return

      elsif sn.user_id == user.user_id
        return

      else
        flash[:error] = 'Error: nick name already taken!'
      end

      raise ActiveRecord::Rollback.new

    elsif user.conf('secured_name') == 'yes'
      sn = SecuredName.find_by_user_id user.user_id
      sn.destroy unless sn.blank?

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
