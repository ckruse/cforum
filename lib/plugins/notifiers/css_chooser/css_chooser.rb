# -*- coding: utf-8 -*-

class CssChooser < Plugin
  def before_handler
    return if cookies[:css_style].blank?
    set('css_style', cookies[:css_style])
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  css_chooser_plugin = CssChooser.new(app_controller)
  app_controller.notification_center.
    register_hook(ApplicationController::BEFORE_HANDLER, css_chooser_plugin)
end

# eof
