module CacheHelper
  def get_cached_entry(realm, key)
    @cache ||= {}
    @cache[realm] ||= {}
    @cache[realm][key]
  end

  def set_cached_entry(realm, key, value)
    @cache ||= {}
    @cache[realm] ||= {}
    @cache[realm][key] = value
  end

  def set_cache(realm, value)
    @cache ||= {}
    @cache[realm] = value
  end

  def reset_cache(realm)
    @cache ||= {}
    @cache.delete(realm)
  end

  def merge_cached_entry(realm, key, value)
    @cache ||= {}
    @cache[realm] ||= {}
    @cache[realm][key] = if @cache[realm][key].blank?
                           value
                         else
                           @cache[realm][key].merge(value)
                         end
  end
end

# eof
