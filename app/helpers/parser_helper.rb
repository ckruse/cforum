# -*- coding: utf-8 -*-

module ParserHelper
  def parse_link(txt, pos, html, max_len)
    i = starts = pos + "[link:".length

    url = nil
    title = nil

    is_title = false

    while i < max_len
      if txt[i] == '@' and txt[i .. (i + "@title=".length - 1)] == '@title='
        url = txt[starts .. (i-1)]
        is_title = true

        starts = i =  i + "@title=".length
        next

      elsif txt[i] == ']'
        if is_title
          title = txt[starts .. (i-1)]
        else
          url = title = txt[starts .. (i-1)]
        end

        break
      end

      i += 1
    end

    if txt[i] != ']'
      html << '['
      return pos + 1
    end

    html << '<a href="' + encode_entities(url) + '">' + title + '</a>'
    i + 1
  end

  def message_to_html(txt)
    # txt = txt.strip

    # txt.gsub! /&/, '&amp;'
    # txt.gsub! /</, '&lt;'
    # txt.gsub! />/, '&gt;'
    # txt.gsub! /"/, '&quot;'

    # # replace every quote sign
    # while txt.gsub! /\u{ECF0}(.*?)\n/, "<span class=\"q\">&gt; \\1</span>\n"
    # end

    # # replace links
    # while txt.gsub! /\[link:([^\]]+)@title=([^\]]+)\]/, '<a href="\1">\2</a>'
    # end
    # while txt.gsub! /\[link:([^\]]+)\]/, '<a href="\1">\1</a>'
    # end

    # txt.gsub! /\n/, "<br>\n"

    # txt.html_safe

    html = ""
    quotes = 0
    max_len = txt.length
    i = 0

    while i < max_len
      c = txt[i]

      case c
      when '&'
        html << '&amp;'
      when '<'
        html << '&lt;'
      when '>'
        html << '&gt;'
      when '"'
        html << '&quot;'
      when "\n"
        quotes.times { html << '</span>' }
        quotes = 0
        html << "<br>\n"
      when "\u{ECF0}"
        html << '<span class="q">&gt; '
        quotes += 1
      else
        if txt[i..(i+"[link:".length-1)] == '[link:'
          i = parse_link(txt, i, html, max_len)
          next
        end

        html << c
      end

      i += 1
    end

    html.gsub! /([[:space:]]{2,})/ do |spaces|
      '&nbsp;' * spaces.length
    end

    # search for the last signature
    sig_pos = html.rindex("<br>\n-- <br>\n")
    unless sig_pos.nil?
      html = html[0..(sig_pos-1)] + "<span class=\"signature\">" + html[sig_pos..-1] + "</span>"
    end

    html.html_safe
  end

  def quote_content(msg, quote_char)
    msg = msg.gsub Regexp.new(CfMessage::QUOTE_CHAR), quote_char
    msg = quote_char + msg.gsub(/\n/, "\n#{quote_char}")
  end

  def content_to_internal(msg, quote_char)
    msg = msg.gsub Regexp.new('^(' + quote_char + ')+', Regexp::MULTILINE) do |data|
      CfMessage::QUOTE_CHAR * (data.length / quote_char.length)
    end

    msg.gsub! /\r\n|\n|\r/, "\n"
    msg
  end

end

# eof