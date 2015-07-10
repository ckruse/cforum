# -*- coding: utf-8 -*-

module LinksHelper
  def cf_link_to(*args, &block)
    if args.last.is_a?(Hash)
      attrs = args.last
    else
      attrs = {}
      args << attrs
    end

    if uconf('open_links_in_tab') == 'yes' and not attrs.has_key?(:target)
      attrs[:target] = '_blank'
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

    if uconf('open_links_in_tab') == 'yes' and not attrs.has_key?(:target)
      attrs[:target] = '_blank'
    end

    link_to_unless(*args)
  end
end

# eof
