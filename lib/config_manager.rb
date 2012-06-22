# Caches the settings which are often used

class ConfigManager

  @@value_cache = {}

  def self.get_value(name, user=nil)
    setting = nil

    unless user.nil?
      setting = CForum::Setting.find(:user => user, :id => name)
    else
      if @@value_cache.has_key?(name) and @@value_cache[name][:expiry] > Time.now
        setting = @@value_cache[name][:value]
      else
        setting = CForum::Setting.find(:id => name)
        @@value_cache[name] = {
          expiry: Time.now + 60,
          value: setting
        }
      end
    end

    setting.value if setting
  end
end

# eof