# -*- coding: utf-8 -*-

module OwnFilesHelper
  def set_own_files
    return unless current_user

    own_css_file = uconf('own_css_file')
    own_js_file  = uconf('own_js_file')

    own_css = uconf('own_css')
    own_js  = uconf('own_js')

    @own_css_file = own_css_file unless own_css_file.blank?
    @own_js_file = own_js_file unless own_js_file.blank?

    @own_css = own_css unless own_css.blank?
    @own_js = own_js unless own_js.blank?
  end
end

# eof
