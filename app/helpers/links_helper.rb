# -*- coding: utf-8 -*-

module LinksHelper
  def url_whitelisted?(url)
    return true unless url =~ /^https?:\/\//
    list = conf('links_white_list').to_s.split(/\015\012|\015|\012/)

    list.each do |l|
      return true if Regexp.new(l, Regexp::IGNORECASE).match(url)
    end

    false
  end

  def cf_link_to(*args, &block)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.second
    url = args.first unless block.blank?
    attrs[:rel] = 'nofollow' if !url_whitelisted?(url) && !attrs.key?(:rel)

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
    attrs[:rel] = 'nofollow' if !url_whitelisted?(url) && !attrs.key?(:rel)

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
    attrs[:rel] = 'nofollow' if !url_whitelisted?(url) && !attrs.key?(:rel)

    link_to_if(*args)
  end
end

# eof
