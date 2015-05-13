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

  def gen_content(content, name, std_replacement = '')
    content  ||= ""

    if current_user
      greeting  = uconf('greeting')
      farewell  = uconf('farewell')
      signature = uconf('signature')

      unless greeting.blank?
        if name.blank?
          greeting.gsub!(/\s*\{\$name\}/, std_replacement)
          greeting.gsub!(/\s*\{\$vname\}/, std_replacement)
        else
          greeting.gsub!(/\{\$name\}/, name)
          greeting.gsub!(/\{\$vname\}/, name.gsub(/\s.*/, ''))
        end

        content = greeting + "\n" + content
      end

      content = content + "\n" + farewell unless farewell.blank?
      content = content + "\n-- \n" + signature unless signature.blank?
    end

    content
  end

  def set_vars(msg, parent)
    if user = current_user
      msg.email    ||= user.conf('email')
      msg.homepage ||= user.conf('url')

      msg.content = gen_content(msg.content, parent.try(:author),
                                I18n.t('plugins.user_data.all'))

    else
      msg.author    ||= cookies[:cforum_author]
      msg.email     ||= cookies[:cforum_email]
      msg.homepage  ||= cookies[:cforum_homepage]
    end
  end

  def show_new_priv_message(msg)
    msg.body = gen_content(msg.body, msg.recipient.try(:username))
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  ud_plugin = UserDataPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, ud_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, ud_plugin)
    app_controller.notification_center.register_hook(MailsController::SHOW_NEW_PRIV_MESSAGE, ud_plugin)
end

# eof
