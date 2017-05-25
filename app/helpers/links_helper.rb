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

  def cf_link_to_unless(*args, &block)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.third
    attrs[:rel] = 'nofollow' if !url_whitelisted?(url) && !attrs.key?(:rel)

    link_to_unless(*args, &block)
  end

  def cf_link_to_if(*args, &block)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    url = args.third
    attrs[:rel] = 'nofollow' if !url_whitelisted?(url) && !attrs.key?(:rel)

    link_to_if(*args, &block)
  end

  def cf_button_to(url, args = {}, &block)
    str = '<form class="button_to" method="' <<
          (args[:method] == 'get' ? 'get' : 'post') << '" action="' <<
          url << '">' << '<button'

    str << ' title="' + encode_entities(args[:title]) + '"' unless args[:title].blank?
    str << ' class="' + encode_entities(args[:class]) + '"' unless args[:class].blank?

    if !args[:data].blank? && !args[:data]['cf-confirm'].blank?
      str << ' data-cf-confirm="' + encode_entities(args[:data]['cf-confirm']) + '"'
    end

    str << ' type="submit">'
    str << (capture { yield }) unless block.blank?
    str << '</button><input type="hidden" name="authenticity_token" value="' <<
      form_authenticity_token << '">'

    unless args[:params].blank?
      for k, v in args[:params]
        str << '<input type="hidden" name="' + encode_entities(k.to_s) + '" value="' + encode_entities(v.to_s) + '">'
      end
    end

    m = args[:method].to_s
    if !m.blank? && (m != 'get') && (m != 'post')
      str << '<input type="hidden" name="_method" value="' << encode_entities(m) << '">'
    end

    str << '</form>'
    str.html_safe
  end
end

# eof
