# -*- coding: utf-8 -*-
def parse_pref(pref)
  url   = nil
  title = nil

  if idx = pref.index("@title=")
    url   = pref[0..(idx - 1)]
    title = pref[(idx + 7)..-1]
  else
    url   = pref
  end

  t, m = url.split ';'
  t = t[2..-1]
  m = m[2..-1]

  return t, m, title
end

ParserHelper.parser_modules['pref'] = {
  html: Proc.new do |tag_name, arg, html|
    if arg.strip.empty?
      html << '[pref:]'
    else
      t, m, title = parse_pref(arg)

      begin
        t = CfThread.find_by_tid!(t.to_i)
        m = t.find_by_mid!(m.to_i)

        url = cf_message_path(t, m)
        title = url if title.blank?

        html << '<a href="' + encode_entities(url) + '">' + encode_entities(title) + "</a>"
      rescue
        html << '[pref:' + encode_entities(arg.strip) + ']'
      end

    end
  end,

  txt: Proc.new do |tag_name, arg, txt|
    t, m, title = parse_pref(arg)

    begin
      t = CfThread.find_by_tid!(t.to_i)
      m = t.find_by_mid!(m.to_i)

      url = cf_message_url(t, m)

      lnk = '[link:' + url
      lnk << "@title=" + title if title
      lnk << ']'

      txt << lnk
    rescue
      html << '[pref:' + arg.strip + ']'
    end
  end
}

# eof