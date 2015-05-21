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
    else
      val
    end
  end

  def conf_val_or_default(name)
    @cf_forum ? conf(name) : ConfigManager::DEFAULTS[name]
  end

  def user_to_class_name(user)
    'author-' + to_class_name(user.is_a?(String) ? user : user.username)
  end

  def to_class_name(nam)
    nam = nam.strip.downcase
    nam.gsub(/[^a-zA-Z0-9]/, '-')
  end
end

require 'pp'
class Object
  def pp_inspect
    PP.pp(self, "")
  end
end


# eof
