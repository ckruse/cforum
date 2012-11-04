# -*- coding: utf-8 -*-

# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager

  @@value_cache = {}

  def self.setting(user = nil, forum = nil)
    unless user.blank?
      user = CfUser.find_by_username(user.to_s) if not user.is_a?(CfUser) and not user.is_a?(Integer)
      user = user.user_id if user.is_a?(CfUser)
    end

    unless forum.blank?
      forum = CfForum.find_by_slug forum.to_s if not forum.is_a?(CfForum) and not forum.is_a?(Integer)
      forum = forum.forum_id if forum.is_a?(CfForum)
    end


    # settings hierarchy:
    # - first, check if settings entry with user_id = user and forum_id = forum exists if forum is not empty
    # - second, check if settings entry with user_id = user exists
    # - third, check if settings entry with forum_id = forum exists if forum is not empty
    # - fourth, check if settings entry with forum_id = nil and user_id = nil exists (aka global config object)
    # - return default value if nothing helps

    settings = CfSetting.
      where('(user_id = ? OR user_id IS NULL) AND (forum_id = ? OR forum_id IS NULL)', forum, user).
      order('user_id, forum_id').
      limit(1).
      first

    return {} if settings.blank?
    settings.options
  end

  def self.get(name, default = nil, user = nil, forum = nil)
    settings = setting(user, forum)
    if settings.has_key?(name)
      return settings[name].nil? ? default : settings[name]
    end

    # if user is nil we had this case in the above statements
    if user
      settings = setting(user)

      if settings.has_key?(name)
        return settings[name].nil? ? default : settings[name]
      end
    end

    # if forum is nil we covered this case in the above statements
    if forum
      settings = setting(nil, forum)

      if settings.has_key?(name)
        return settings[name].nil? ? default : settings[name]
      end
    end

    # if one of them is set, we covered this case in the above statements
    if user or forum
      settings = setting()

      if settings.has_key?(name)
        return settings[name].nil? ? default : settings[name]
      end
    end

    default
  end

end

# eof