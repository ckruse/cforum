class ConfigManager
  @@value_cache = {}
  def self.get_value(name, user=nil)
    s = nil

    unless user.nil?
      s = CForum::Setting.find(:user => user, :id => name)
    else
      if @@value_cache.has_key?(name) and @@value_cache[name][:expiry] > Time.now
        s = @@value_cache[name][:value]
      else
        s = CForum::Setting.find(:id => name)
        @@value_cache[name] = {
          expiry: Time.now + 60,
          value: s
        }
      end
    end

    s = s.value if s
    s
  end
end

# eof