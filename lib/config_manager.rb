# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager

  @@value_cache = {}

  def self.setting(name, default = nil, user = nil)
    ret = default

    unless user.nil?
      usr = CfUser.find_by_username(user)
      ret = usr.settings[name] if usr and usr.settings[name]
    else
      setting = nil

      if @@value_cache.has_key?(name) and @@value_cache[name][:expiry] > Time.now
        setting = @@value_cache[name][:value]
      else
        setting = CfSetting.find_by_id(name)
        @@value_cache[name] = {
          expiry: Time.now + 60,
          value: setting
        }
      end

      ret = setting.value if setting
    end

    ret
  end

  def self.user_setting(user, setting)
    self.get_setting(setting, nil, user)
  end
end

# eof