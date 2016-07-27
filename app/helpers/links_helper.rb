# -*- coding: utf-8 -*-

module LinksHelper
  def is_url_whitelisted?(url)
    return true if not url =~ /^https?:\/\//
    list = conf('links_white_list').to_s.split(/\015\012|\015|\012/)

    list.each do |l|
      return true if Regexp.new(l, Regexp::IGNORECASE).match(url)
    end

    return false
  end

  def cf_link_to(*args, &block)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.second
    url = args.first if not block.blank?
    if not is_url_whitelisted?(url) and not attrs.has_key?(:rel)
      attrs[:rel] = 'nofollow'
    end

    link_to(*args, &block)
  end

  def cf_link_to_unless(*args)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.third
    if not is_url_whitelisted?(url) and not attrs.has_key?(:rel)
      attrs[:rel] = 'nofollow'
    end


    link_to_unless(*args)
  end

  def cf_link_to_if(*args)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.third
    if not is_url_whitelisted?(url) and not attrs.has_key?(:rel)
      attrs[:rel] = 'nofollow'
    end


    link_to_if(*args)
  end
end

# eof
