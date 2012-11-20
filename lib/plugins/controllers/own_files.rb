# -*- coding: utf-8 -*-

class OwnFilesPlugin < Plugin
  def before_handler
    return unless current_user

    own_css_file = uconf('own_css_file')
    own_js_file  = uconf('own_js_file')

    own_css = uconf('own_css')
    own_js  = uconf('own_js')

    set('own_css_file', own_css_file) unless own_css_file.blank?
    set('own_js_file', own_js_file) unless own_js_file.blank?

    set('own_css', own_css) unless own_css.blank?
    set('own_js', own_js) unless own_js.blank?
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  of_plugin = OwnFilesPlugin.new(app_controller)
  app_controller.notification_center.register_hook(ApplicationController::BEFORE_HANDLER, of_plugin)
end

# eof