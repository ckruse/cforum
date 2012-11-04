# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager

  @@value_cache = {}

  def self.setting(user = nil, forum = nil)
    unless user.blank?
      user = CfUser.find_by_username(user.to_s) if not user.is_a?(CfUser) or not user.is_a?(Integer)
      user = user.user_id if user.is_a?(CfUser)
    end

    unless forum.blank?
      forum = CfForum.find_by_slug forum.to_s if not forum.is_a?(CfForum) or not forum.is_a?(Integer)
      forum = forum.forum_id if forum.is_a?(CfForum)
    end


    # settings hierarchy:
    # - first, check if settings entry with user_id = user and forum_id = forum exists if forum is not empty
    # - second, check if settings entry with user_id = user exists
    # - third, check if settings entry with forum_id = forum exists if forum is not empty
    # - fourth, check if settings entry with forum_id = nil and user_id = nil exists (aka global config object)
    # - return default value if nothing helps

    settings = nil
    settings = CfSetting.where(user_id: user, forum_id: forum).first if not forum.blank?
    settings = CfSetting.where(user_id: user).first if settings.blank?
    settings = CfSetting.where(forum_id: forum).first if settings.blank? and not forum.blank?
    settings = CfSetting.where(forum_id: nil, user_id: nil).first if settings.blank?


    settings.blank? ? {} : settings
  end
end

# eof