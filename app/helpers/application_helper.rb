# -*- coding: utf-8 -*-

module ApplicationHelper
  include CForum::Tools

  def current_forum
    if !params[:curr_forum].blank? && (params[:curr_forum] != 'all')
      @_current_forum = Forum.find_by_slug(params[:curr_forum]) if !@_current_forum || @_current_forum.slug != params[:curr_forum]
      raise ActiveRecord::RecordNotFound unless @_current_forum
      return @_current_forum
    end

    @_current_forum = nil
  end

  def date_format(type = 'date_format_default')
    val = uconf(type)
    val.blank? ? '%d.%m.%Y %H:%M' : val
  end

  def human_val(val)
    case val
    when 'yes'
      t('global.yeah')
    when 'no'
      t('global.nope')
    when 'close', 'hide'
      t('admin.forums.settings.' + val + '_subtree')
    when 'thread-view', 'nested-view'
      t('users.' + val)
    else
      val
    end
  end

  def conf_val_or_default(name)
    @forum ? conf(name) : ConfigManager::DEFAULTS[name]
  end

  def is_global_conf(name)
    return false if @forum.blank?
    @global_settings ||= Setting.where('user_id IS NULL and forum_id IS NULL').first
    return false if @global_settings.blank?
    @global_settings.options.key?(name)
  end

  def user_to_class_name(user)
    'author-' + to_class_name(user.is_a?(String) ? user : user.username)
  end

  def to_class_name(nam)
    nam = nam.strip.downcase
    nam.gsub(/[^a-zA-Z0-9]/, '-')
  end

  def cf_button_to(url, args = {}, &block)
    str = '<form class="button_to" method="' <<
          (args[:method] == 'get' ? 'get' : 'post') << '" action="' <<
          url << '">' << '<button'

    str << ' title="' + encode_entities(args[:title]) + '"' unless args[:title].blank?
    str << ' class="' + encode_entities(args[:class]) + '"' unless args[:class].blank?
    str << ' data-cf-confirm="' + encode_entities(args[:data]['cf-confirm']) + '"' if !args[:data].blank? && !args[:data]['cf-confirm'].blank?
    str << ' type="submit">'
    str << capture { yield } unless block.blank?
    str << '</button><input type="hidden" name="authenticity_token" value="' <<
      form_authenticity_token << '">'

    unless args[:params].blank?
      for k, v in args[:params]
        str << '<input type="hidden" name="' + encode_entities(k.to_s) + '" value="' + encode_entities(v.to_s) + '">'
      end
    end

    m = args[:method].to_s
    if !m.blank? && (m != 'get') && (m != 'post')
      str << '<input type="hidden" name="_method" value="' << encode_entities(m) << '">'
    end

    str << '</form>'
    str.html_safe
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
    return I18n.translate('relative_time.months', count: (diff_in_minutes / 43_200.0).round) if diff_in_minutes < 518_400
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

require 'pp'
class Object
  def pp_inspect
    PP.pp(self, '')
  end
end

# eof
