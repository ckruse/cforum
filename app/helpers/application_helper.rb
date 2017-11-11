module ApplicationHelper
  include CForum::Tools

  def current_forum
    return if params[:curr_forum] == 'all' || params[:curr_forum].blank?

    if @_current_forum.try(:slug) != params[:curr_forum]
      @_current_forum = Forum.find_by!(slug: params[:curr_forum])
    end

    @_current_forum
  end

  def date_format(type = 'date_format_default')
    val = uconf(type)
    val.blank? ? '%d.%m.%Y %H:%M' : val
  end

  def user_to_class_name(user)
    'author-' + to_class_name(user.is_a?(String) ? user : user.username)
  end

  def to_class_name(nam)
    nam = nam.strip.downcase
    nam.gsub(/[^a-zA-Z0-9]/, '-')
  end

  def embedded_svg(filename, options = {})
    assets = Rails.application.assets
    file = assets.find_asset(filename).to_s.force_encoding('UTF-8')

    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css 'svg'
    svg['class'] = options[:class] if options[:class].present?

    raw doc
  end

  def relative_time(date)
    diff_in_minutes = ((Time.now - date) / 60.0).round
    return I18n.translate('relative_time.minutes', count: diff_in_minutes) if diff_in_minutes < 60
    return I18n.translate('relative_time.hours', count: (diff_in_minutes / 60.0).round) if diff_in_minutes < 1440
    return I18n.translate('relative_time.days', count: (diff_in_minutes / 1440.0).round) if diff_in_minutes < 43_200

    if diff_in_minutes < 518_400
      return I18n.translate('relative_time.months', count: (diff_in_minutes / 43_200.0).round)
    end

    I18n.translate('relative_time.years', count: (diff_in_minutes / 518_400.0).round)
  end

  def uconf(name)
    @config_manager ||= ConfigManager.new
    @config_manager.get(name, current_user, current_forum)
  end

  def conf(name)
    @config_manager ||= ConfigManager.new
    @config_manager.get(name, nil, current_forum)
  end

  def view_all
    @view_all ||= false
  end
end

# eof
