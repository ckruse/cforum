# -*- coding: utf-8 -*-

class HighlightPlugin < Plugin
  def to_class_name(nam)
    nam = nam.strip.downcase
    'author-' + nam.gsub(/[^a-zA-Z0-9]/, '-')
  end

  def show_threadlist(threads)
    return unless current_user

    highlighted_users = uconf('highlighted_users')
    highlighted_users ||= ''

    user_map = {}
    highlighted_users.split(',').each do |s|
      user_map[s.strip.downcase] = true
    end

    threads.each do |t|
      t.sorted_messages.each do |m|
        if user_map[m.author.strip.downcase]
          m.attribs['classes'] << 'highlighted-user'
          m.attribs['classes'] << to_class_name(m.author)
        end
      end
    end
  end

  def show_message(thread, message, votes)
    show_threadlist([thread])
  end

  def show_thread(thread, message, votes)
    show_threadlist([thread])
  end

  def showing_settings(user)
    users = CfUser.where(username: user.conf('highlighted_users', '').split(/\s*,\s*/))
    set('highlighted_users_list', users)
  end

  def saving_settings(user, settings)
    unless settings.options["highlighted_users"].blank?
      users = CfUser.where(user_id: JSON.parse(settings.options["highlighted_users"]))
      settings.options["highlighted_users"] = (users.map {|u| u.username}).join(",")
    end
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  hl_plugin = HighlightPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, hl_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_MESSAGE, hl_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_THREAD, hl_plugin)

  app_controller.notification_center.register_hook(UsersController::SHOWING_SETTINGS, hl_plugin)
  app_controller.notification_center.register_hook(UsersController::SAVING_SETTINGS, hl_plugin)
end

# eof
