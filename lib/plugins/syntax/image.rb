# -*- coding: utf-8 -*-

require 'uri'

ParserHelper.parser_modules['img'] = {
  type: :after_parsing,
  html: Proc.new do |tag_name, args, content, html|
    if args.empty? and content.empty?
      html << '[img][/img]'
    else
      alt = content
      url = args.empty? ? content : args[0]

      if url =~ URI::regexp
        img = '<img src="' + encode_entities(url.strip) + '"'

        if alt
          title = encode_entities(alt.strip)
          img << ' alt="' + title + '" title="' + title + '"'
        end

        img << '>'

        html << img
      else
        if args.empty?
          html << '[img]' + encode_entities(url.strip) + '[/img]'
        else
          html << '[img=' + encode_entities(url.strip) + ']' + encode_entities(alt.strip) + '[/img]'
        end
      end

    end
  end,

  txt: Proc.new do |tag_name, args, content, txt|
    if args.empty?
      txt << '[img]' + encode_entities(content) + '[/img]'
    else
      txt << '[img=' + encode_entities(args[0].strip) + ']' + encode_entities(content.strip) + '[/img]'
    end
  end
}

# eof
