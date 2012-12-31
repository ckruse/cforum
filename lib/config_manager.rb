# -*- coding: utf-8 -*-

# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager
  def initialize
    @value_cache = {:users => {}, :forums => {}, :global => nil}
  end

  def read_settings(user = nil, forum = nil)
    if not user.blank? and not @value_cache[:users].has_key?(user)
      @value_cache[:users][user] = CfSetting.find_by_user_id(user)
    end

    if not forum.blank? and not @value_cache[:forums].has_key?(forum)
      @value_cache[:forums][forum] = CfSetting.find_by_forum_id(forum)
    end

    if not @value_cache.has_key?(:global)
      @value_cache[:global] = CfSetting.where('user_id IS NULL and forum_id IS NULL').first
    end
  end

  def get(name, default = nil, user = nil, forum = nil)
    unless user.blank?
      user = CfUser.find_by_username(user.to_s) if not user.is_a?(CfUser) and not user.is_a?(Integer)
      user = user.user_id if user.is_a?(CfUser)
    end

    unless forum.blank?
      forum = CfForum.find_by_slug forum.to_s if not forum.is_a?(CfForum) and not forum.is_a?(Integer)
      forum = forum.forum_id if forum.is_a?(CfForum)
    end

    read_settings(user, forum)

    if not @value_cache[:users][user].blank? and @value_cache[:users][user].options.has_key?(name)
      return @value_cache[:users][user].options[name].nil? ? default : @value_cache[:users][user].options[name]
    end

    if not @value_cache[:forums][forum].blank? and @value_cache[:forums][forum].options.has_key?(name)
      return @value_cache[:forums][forum].options[name].nil? ? default : @value_cache[:forums][forum].options[name]
    end

    if @value_cache[:global] and @value_cache[:global].options.has_key?(name)
      return @value_cache[:global].options[name].nil? ? default : @value_cache[:global].options[name]
    end

    default
  end

end

# eof
