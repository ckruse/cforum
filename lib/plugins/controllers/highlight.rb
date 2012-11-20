# -*- coding: utf-8 -*-

class HighlightPlugin < Plugin
  def show_threadlist(threads)
    return unless current_user

    highlighted_users = uconf('highlighted_users')
    highlighted_users ||= ''

    user_map = {}
    highlighted_users.split(',').each do |s|
      user_map[s.strip.downcase] = true
    end

    threads.each do |t|
      t.messages.each do |m|
        m.attribs['classes'] << 'highlighted-user' if user_map[m.author.strip.downcase]
      end
    end
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  hl_plugin = HighlightPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, hl_plugin)
end

# eof