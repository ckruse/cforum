# -*- coding: utf-8 -*-

class UserDataPlugin < Plugin
  def show_new_thread(thread)
    return if get('preview')
    set_vars(thread.message, nil)
  end

  def show_new_message(thread, parent, message)
    return if get('preview')
    set_vars(message, parent)
  end

  def set_vars(msg, parent)
    if user = current_user
      msg.email    ||= user.conf('email')
      msg.homepage ||= user.conf('url')

      msg.content  ||= ""

      greeting  = user.conf('greeting')
      farewell  = user.conf('farewell')
      signature = user.conf('signature')

      unless greeting.blank?
        if parent
          greeting.gsub!(/\{\$name\}/, parent.author)
          greeting.gsub!(/\{\$vname\}/, parent.author.gsub(/\s.*/, ''))
        else
          greeting.gsub!(/\{\$name\}/, I18n.t('plugins.user_data.all'))
          greeting.gsub!(/\{\$vname\}/, I18n.t('plugins.user_data.all'))
        end

        msg.content = greeting + "\n" + msg.content
      end

      msg.content = msg.content + "\n" + farewell unless farewell.blank?
      msg.content = msg.content + "\n-- \n" + signature unless signature.blank?

    else
      msg.author    ||= cookies[:cforum_author]
      msg.email     ||= cookies[:cforum_email]
      msg.homepage  ||= cookies[:cforum_homepage]
    end
  end

  def show_new_priv_message(msg)
    msg.body  ||= ""

    greeting  = uconf('greeting')
    farewell  = uconf('farewell')
    signature = uconf('signature')

    unless greeting.blank?
      if msg.recipient
        greeting.gsub!(/\{\$name\}/, msg.recipient.username)
        greeting.gsub!(/\{\$vname\}/, msg.recipient.username.gsub(/\s.*/, ''))
      else
        greeting.gsub!(/\s*\{\$name\}/, '')
        greeting.gsub!(/\s*\{\$vname\}/, '')
      end

      msg.body = greeting + "\n" + msg.body
    end

    msg.body = msg.body + "\n" + farewell unless farewell.blank?
    msg.body = msg.body + "\n-- \n" + signature unless signature.blank?
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  ud_plugin = UserDataPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, ud_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, ud_plugin)
    app_controller.notification_center.register_hook(MailsController::SHOW_NEW_PRIV_MESSAGE, ud_plugin)
end

# eof
