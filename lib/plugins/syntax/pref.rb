# -*- coding: utf-8 -*-

ParserHelper.parser_modules['pref'] = {
  html: Proc.new do |tag_name, args, content, html|
    if args.empty?
      if content.empty?
        html << '[pref][/pref]'
      else
        html << '[pref]' + encode_entities(content) + '[/pref]'
      end
    else
      tid = args['t']
      mid = args['m']
      title = content

      begin
        t = CfThread.find_by_tid!(tid)
        m = t.find_by_mid!(mid.to_i)

        url = cf_message_url(t, m)
        title = url if title.blank?

        html << '<a href="' + encode_entities(url) + '">' + encode_entities(title) + "</a>"

      rescue
        html << '[pref t=' + tid + ' m=' + mid + ']'
        html << content unless content.blank?
        html << '[/pref]'
      end

    end
  end,

  txt: Proc.new do |tag_name, args, content, txt|
    if args.empty?
      if content.empty?
        txt << '[pref][/pref]'
      else
        txt << '[pref]' + content + '[/pref]'
      end
    else
      tid = args['t']
      mid = args['m']
      title = content

      begin
        t = CfThread.find_by_tid!(tid)
        m = t.find_by_mid!(mid.to_i)

        url = cf_message_url(t, m)

        lnk = '[url'
        if title.blank?
          lnk << ']' + url
        else
          lnk << '=' + url + ']' + title
        end

        txt << lnk + '[/url]'
      rescue
        lnk = '[pref t=' + args['t'] + ' m=' + args['m'] +  ']'
        lnk << content unless content.blank?
        lnk << '[/pref]'

        txt << lnk
      end
    end
  end
}

# eof
