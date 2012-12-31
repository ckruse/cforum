# -*- coding: utf-8 -*-

ParserHelper.parser_modules['code'] = {
  type: :before_parsing,
  html: Proc.new do |tag_name, args, content, html|
    if args.empty? or not lang = args['lang']
      html << "<code>" + content + "</code>"
    else
      html << "<code title=\"" + encode_entities(lang) + "\">" + CodeRay.scan(content, lang).html(wrap: nil) + "</code>"
    end
  end,

  txt: Proc.new do |tag_name, args, content, txt|
    txt << "[code"
    txt << " lang=" + args['lang'] unless args.empty?
    txt << "]" + content + "[/code]"
  end
}

# eof
