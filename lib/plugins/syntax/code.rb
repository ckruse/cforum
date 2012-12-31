# -*- coding: utf-8 -*-

ParserHelper.parser_modules['code'] = {
  html: Proc.new do |tag_name, args, content, html|
    if args.empty? or not lang = args['lang']
      html << "<code>" + content + "</code>"
    else
      # TODO: we have to find a much better way
      # to handle HTML converted input; maybe something
      # like "pre converting syntax plugins"
      content.gsub! '&lt;', '<'
      content.gsub! '&gt;', '>'
      content.gsub! '&quot;', '"'
      content.gsub! '&amp;', '&'

      html << "<code>" + CodeRay.scan(content, lang).html(:wrap => :div) + "</code>"
    end
  end,

  txt: Proc.new do |tag_name, args, content, txt|
    txt << "[code"
    txt << " lang=" + args['lang'] unless args.empty?
    txt << "]" + content + "[/code]"
  end
}

# eof
