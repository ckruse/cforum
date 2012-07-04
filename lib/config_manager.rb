# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager

  @@value_cache = {}

  def self.setting(name, default = nil, user = nil)
    ret = default

    unless user.nil?
      user = CfUser.find_by_username(user.to_s) if not user.is_a?(CfUser) or not user.is_a?(Integer)
      user = user.user_id if user.is_a?(CfUser)
    end

    settings = CfSetting.where(user_id: user, name: name)

    settings.blank? ? ret : settings
  end
end

# eof