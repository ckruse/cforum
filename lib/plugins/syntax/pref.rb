# -*- coding: utf-8 -*-

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