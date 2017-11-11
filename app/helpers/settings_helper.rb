module SettingsHelper
  def human_val(val)
    case val
    when 'yes'
      t('global.yeah')
    when 'no'
      t('global.nope')
    when 'close', 'hide'
      t('admin.forums.settings.' + val + '_subtree')
    when 'thread-view', 'nested-view', 'ascending', 'descending', 'newest-first'
      t('users.' + val)
    else
      val
    end
  end

  def conf_val_or_default(name)
    @forum ? conf(name) : ConfigManager::DEFAULTS[name]
  end

  def global_conf?(name)
    return false if @forum.blank?
    @global_settings ||= Setting.where('user_id IS NULL and forum_id IS NULL').first
    return false if @global_settings.blank?
    @global_settings.options.key?(name)
  end
end

# eof
