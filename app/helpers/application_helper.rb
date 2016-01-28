# -*- coding: utf-8 -*-

module ApplicationHelper
  include CForum::Tools

  def current_forum
    if not params[:curr_forum].blank? and not params[:curr_forum] == 'all'
      @_current_forum = CfForum.find_by_slug(params[:curr_forum]) if !@_current_forum || @_current_forum.slug != params[:curr_forum]
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
    @cf_forum ? conf(name) : ConfigManager::DEFAULTS[name]
  end

  def is_global_conf(name)
    return false if @cf_forum.blank?
    @global_settings ||= CfSetting.where('user_id IS NULL and forum_id IS NULL').first
    @global_settings.options.has_key?(name)
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
          url << '">' << "<button"

    str << ' title="' + encode_entities(args[:title]) + '"' unless args[:title].blank?
    str << ' class="' + encode_entities(args[:class]) + '"' unless args[:class].blank?
    str << ' data-confirm="' + encode_entities(args[:data][:confirm]) + '"' if not args[:data].blank? and not args[:data][:confirm].blank?
    str << ' type="submit">'
    unless block.blank?
      str << capture { block.call }
    end
    str << '</button><input type="hidden" name="authenticity_token" value="' <<
      form_authenticity_token << '">'

    unless args[:params].blank?
      for k, v in args[:params]
        str << '<input type="hidden" name="' + encode_entities(k.to_s) + '" value="' + encode_entities(v.to_s) + '">'
      end
    end

    m = args[:method].to_s
    if not m.blank? and m != 'get' and m != 'post'
      str << '<input type="hidden" name="_method" value="' << encode_entities(m) << '">'
    end

    str << '</form>'
    return str.html_safe
  end

  def embedded_svg(filename, options = {})
    assets = Rails.application.assets
    file = assets.find_asset(filename).to_s.force_encoding("UTF-8")

    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css "svg"
    svg["class"] = options[:class] if options[:class].present?

    raw doc
  end

  def relative_time(date)
    diff_in_minutes = ((Time.now - date) / 60.0).round
    return I18n.translate('relative_time.minutes', count: diff_in_minutes) if diff_in_minutes < 60
    return I18n.translate('relative_time.hours', count: (diff_in_minutes / 60.0).round) if diff_in_minutes < 1440
    return I18n.translate('relative_time.days', count: (diff_in_minutes / 1440.0).round) if diff_in_minutes < 43200
    return I18n.translate('relative_time.months', count: (diff_in_minutes / 43200.0).round) if diff_in_minutes < 518400
    return I18n.translate('relative_time.years', count: (diff_in_minutes / 518400.0).round)
  end
end

require 'pp'
class Object
  def pp_inspect
    PP.pp(self, "")
  end
end


# eof
