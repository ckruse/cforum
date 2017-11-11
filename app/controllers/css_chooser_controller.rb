class CssChooserController < ApplicationController
  def choose_css
    @css_styles = conf('css_styles').to_s.split(/\015\012|\012|\015/)
  end

  def css_chosen
    if params[:css_style].blank?
      cookies.delete(:css_style)
    else
      cookies[:css_style] = { value: params[:css_style],
                              expires: 1.year.from_now }
    end

    redirect_to root_path, notice: t('plugins.choose_css.css_chosen')
  end
end

# eof
