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
        html << '<a href="' + encode_entities(url.strip) + '">' + encode_entities(title.strip) + '</a>'
      rescue
        html << "[link:" + encode_entities(arg.strip) + "]"
      end

    end
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[link:' + arg.strip + ']'
  end
}

# eof