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
    highlight_self = uconf('highlight_self') == 'yes'

    return if highlighted_users.blank? and not highlight_self

    user_map = {}
    highlighted_users.split(',').each do |s|
      user_map[s.strip.downcase] = true
    end

    cu_nam = current_user.username.strip.downcase

    threads.each do |t|
      t.sorted_messages.each do |m|
        n = m.author.strip.downcase

        if user_map[n]
          m.attribs['classes'] << 'highlighted-user'
          m.attribs['classes'] << to_class_name(m.author)
        end

        if highlight_self and n == cu_nam
          m.attribs['classes'] << 'highlighted-self'
          m.attribs['classes'] << to_class_name(m.author)
        end
      end
    end
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist
  alias show_interesting_threadlist show_threadlist

  def show_message(thread, message, votes)
    show_threadlist([thread])
  end
  alias show_new_message show_message

  def show_thread(thread, message, votes)
    show_threadlist([thread])
  end

  def showing_settings(user)
    users = CfUser.where(username: user.conf('highlighted_users').split(/\s*,\s*/))
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
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, hl_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::SHOW_THREAD, hl_plugin)

  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST, hl_plugin)
  app_controller.notification_center.
    register_hook(InvisibleThreadsPluginController::SHOW_INVISIBLE_THREADLIST,
                  hl_plugin)
  app_controller.notification_center.
    register_hook(InterestingThreadsPluginController::SHOW_INTERESTING_THREADLIST,
                  hl_plugin)

  app_controller.notification_center.register_hook(UsersController::SHOWING_SETTINGS, hl_plugin)
  app_controller.notification_center.register_hook(UsersController::SAVING_SETTINGS, hl_plugin)
end

# eof
