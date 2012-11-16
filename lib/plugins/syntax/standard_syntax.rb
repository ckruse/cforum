# -*- coding: utf-8 -*-

require 'uri'

ParserHelper.parser_modules['link'] = {
  html: Proc.new do |tag_name, arg, html|
    if arg.strip.empty?
      html << '[link:]'
    else
      url   = ""
      title = ""

      if idx = arg.index("@title=")
        url = arg[0..(idx-1)]
        title = arg[(idx + 7)..-1]
      else
        url   = arg
        title = arg
      end

      begin
        u = URI.parse(url)
        html << '<a href="' + CForum::Tools.encode_entities(url.strip) + '">' + CForum::Tools.encode_entities(title.strip) + '</a>'
      rescue
        html << "[link:" + CForum::Tools.encode_entities(arg.strip) + "]"
      end

    end
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[link:' + arg.strip + ']'
  end
}

ParserHelper.parser_modules['image'] = {
  html: Proc.new do |tag_name, arg, html|
    if arg.strip.empty?
      html << '[image:]'
    else
      url   = ""
      title = nil

      if idx = arg.index("@alt=")
        url = arg[0..(idx-1)]
        title = arg[(idx + 5)..-1]
      else
        url   = arg
      end

      begin
        URI.parse(url)
        img = '<img src="' + CForum::Tools.encode_entities(url.strip) + '"'

        if title
          title = CForum::Tools.encode_entities(title.strip)
          img << ' alt="' + title + '" title="' + title + '"'
        end

        img << '>'

        html << img
      rescue
        html << '[image:' + CForum::Tools.encode_entities(arg.strip) + ']'
      end

    end
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[image:' + arg.strip + ']'
  end
}

# eof