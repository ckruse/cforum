module LinksHelper
  def url_whitelisted?(url)
    return true if url.is_a?(ApplicationRecord)
    return true unless url.match?(%r{^https?://})
    list = conf('links_white_list').to_s.split(/\015\012|\015|\012/)

    list.each do |l|
      return true if Regexp.new(l, Regexp::IGNORECASE).match?(url)
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
    url = args.first if block.present?
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
    # let link_to_unless() handle url.nil? cases
    attrs[:rel] = 'nofollow' if !url.nil? && !url_whitelisted?(url) && !attrs.key?(:rel)

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
    attrs[:rel] = 'nofollow' if !url.nil? && !url_whitelisted?(url) && !attrs.key?(:rel)

    link_to_if(*args, &block)
  end

  def cf_button_to(url, args = {}, &block)
    str = '<form class="button_to" method="' <<
          (args[:method] == 'get' ? 'get' : 'post') << '" action="' <<
          url << '">' << '<button'

    str << ' title="' + encode_entities(args[:title]) + '"' if args[:title].present?
    str << ' class="' + encode_entities(args[:class]) + '"' if args[:class].present?

    if args[:data].present? && args[:data]['cf-confirm'].present?
      str << ' data-cf-confirm="' + encode_entities(args[:data]['cf-confirm']) + '"'
    end

    str << ' type="submit">'
    str << (capture { yield }) if block.present?
    str << '</button><input type="hidden" name="authenticity_token" value="' <<
      form_authenticity_token << '">'

    if args[:params].present?
      args[:params].each do |k, v|
        str << '<input type="hidden" name="' + encode_entities(k.to_s) + '" value="' + encode_entities(v.to_s) + '">'
      end
    end

    m = args[:method].to_s
    if m.present? && (m != 'get') && (m != 'post')
      str << '<input type="hidden" name="_method" value="' << encode_entities(m) << '">'
    end

    str << '</form>'
    str.html_safe
  end
end

# eof
