module OwnFilesHelper
  def set_own_files
    return unless current_user

    own_css_file = uconf('own_css_file')
    own_js_file  = uconf('own_js_file')

    own_css = uconf('own_css')
    own_js  = uconf('own_js')

    @own_css_file = own_css_file if own_css_file.present?
    @own_js_file = own_js_file if own_js_file.present?

    @own_css = own_css if own_css.present?
    @own_js = own_js if own_js.present?
  end
end

# eof
