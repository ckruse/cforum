# -*- coding: utf-8 -*-

class TitlePlugin < Plugin
  def before_handler
    title = []
    return if current_user.blank?

    if uconf('show_unread_notifications_in_title', 'no') == 'yes'
      notifications = get('notifications') || []
      title << notifications.length.to_s
    end

    if uconf('show_unread_pms_in_title', 'no') == 'yes'
      priv_msgs = CfPrivMessage.where(owner_id: current_user.user_id, is_read: false).count
      title << priv_msgs.to_s
    end

    set('title_infos', '(' + title.join("/") + ') ') unless title.blank?
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  title_plugin = TitlePlugin.new(app_controller)

  app_controller.notification_center.register_hook(ApplicationController::BEFORE_HANDLER, title_plugin)
end

# eof
