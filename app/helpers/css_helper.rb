module CssHelper
  def set_css
    return if cookies[:css_style].blank?
    @css_style = cookies[:css_style]
  end
end

# eof
