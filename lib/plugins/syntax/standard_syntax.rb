# -*- coding: utf-8 -*-

ParserHelper.parser_modules['link'] = {
  html: Proc.new do |tag_name, arg, html|
    url   = ""
    title = ""

    if idx = arg.index("@title=")
      url = arg[0..idx]
      title = arg[(idx + 7)..-1]
    else
      url   = arg
      title = arg
    end

    html << '<a href="' + CForum::Tools.encode_entities(url.strip) + '">' + CForum::Tools.encode_entities(title.strip) + '</a>'
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[link:' + arg.strip + ']'
  end
}

ParserHelper.parser_modules['image'] = {
  html: Proc.new do |tag_name, arg, html|
    url   = ""
    title = nil

    if idx = arg.index("@alt=")
      url = arg[0..idx]
      title = arg[(idx + 7)..-1]
    else
      url   = arg
    end

    img = '<img src="' + CForum::Tools.encode_entities(url.strip) + '"'

    if title
      title = CForum::Tools.encode_entities(title.strip)
      img << ' alt="' + title + '" title="' + title + '"'
    end

    img << '>'

    html << img
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[image:' + arg.strip + ']'
  end
}

# eof