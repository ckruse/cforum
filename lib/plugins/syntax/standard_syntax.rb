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
        url = arg[0..idx]
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
        url = arg[0..idx]
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

ParserHelper.parser_modules['pref'] = {
  html: Proc.new do |tag_name, arg, html|
    if arg.strip.empty?
      html << '[pref:]'
    else
      t     = nil
      m     = nil
      url   = ""
      title = nil

      if idx = arg.index("@title=")
        url   = arg[0..(idx - 1)]
        title = arg[(idx + 7)..-1]
      else
        url   = arg
      end

      t, m = url.split ';'
      t = t[2..-1]
      m = m[2..-1]

      begin
        t = CfThread.find_by_tid!(t.to_i)
        m = t.find_by_mid!(m.to_i)

        url = CForum::Tools.cf_message_path(t, m)
        title = url if title.blank?

        html << '<a href="' + CForum::Tools.encode_entities(url) + '">' + CForum::Tools.encode_entities(title) + "</a>"
      rescue
        html << '[pref:' + CForum::Tools.encode_entities(arg.strip) + ']'
      end

    end
  end,

  txt: Proc.new do |tag_name, arg, txt|
    txt << '[pref:' + arg.strip + ']'
  end
}

# eof