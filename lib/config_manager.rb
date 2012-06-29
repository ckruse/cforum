# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager

  @@value_cache = {}

  def self.get_setting(name, default = nil, user = nil)
    setting = nil

    unless user.nil?
      usr = CForum::User.find_by_id(user)
      setting = usr.settings[name] if usr and usr.settings[name]
    else
      if @@value_cache.has_key?(name) and @@value_cache[name][:expiry] > Time.now
        setting = @@value_cache[name][:value]
      else
        setting = CForum::Setting.find_by_id(name)
        @@value_cache[name] = {
          expiry: Time.now + 60,
          value: setting
        }
      end
    end

    ret = default
    ret = setting.value if setting
    ret
  end
end

# eof