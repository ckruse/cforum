# -*- coding: utf-8 -*-

class SuspiciousPoster < Plugin
  def initialize(*args)
    super(*args)
  end

  def show_threadlist(threads)
    return if not current_user.blank? and uconf('mark_suspicious') == 'no'

    threads.each do |t|
      t.sorted_messages.each do |m|
        m.attribs["classes"] << 'suspicious' if check_name(m.author)
      end
    end
  end
  alias show_archive_threadlist show_threadlist
  alias show_invisible_threadlist show_threadlist
  alias show_interesting_threadlist show_threadlist

  def show_thread(thread, message = nil, votes = nil)
    return if not current_user.blank? and uconf('mark_suspicious') == 'no'

    thread.sorted_messages.each do |m|
      m.attribs['classes'] << 'suspicious' if check_name(m.author)
    end
  end

  def show_message(thread, message, votes)
    return if not current_user.blank? and uconf('mark_suspicious') == 'no'
    show_thread(thread)
  end

  private
  def check_name(name)
    name.each_codepoint do |cp|
      return true if cp > 255
    end

    return false
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  suspicious_plugin = SuspiciousPoster.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST, suspicious_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_THREAD, suspicious_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::SHOW_MESSAGE, suspicious_plugin)

  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST,
                  suspicious_plugin)
  app_controller.notification_center.
    register_hook(InvisibleThreadsPluginController::SHOW_INVISIBLE_THREADLIST,
                  suspicious_plugin)
  app_controller.notification_center.
    register_hook(InterestingThreadsPluginController::SHOW_INTERESTING_THREADLIST,
                  suspicious_plugin)
end

# eof
