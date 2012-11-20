# -*- coding: utf-8 -*-

module ParserHelper
  @@parser_modules = {}

  def self.parser_modules
    @@parser_modules
  end

  def message_to_html(txt)
    quote_char = encode_entities(uconf('quote_char', '> '))

    html    = ""
    quotes  = 0
    max_len = txt.length
    i       = 0

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
      when CfMessage::QUOTE_CHAR
        html << '<span class="q"> ' + quote_char
        quotes += 1

      # possible that we got a tag, check for it
      when '['
        j = i

        tag_name = ""
        arg      = ""

        while j < max_len and txt[j] != ':' and txt[j] != ']'
          j += 1
        end

        tag_name = txt[(i+1)..(j-1)] if txt[j] == ':' or txt[j] == ']'

        if txt[j] == ':'
          old = j
          while j < max_len and txt[j] != ']'
            j += 1
          end

          if txt[j] != ']'
            i += 1
            html << '['
            next
          end

          arg = txt[(old+1)..(j-1)]

        elsif txt[j] == ']'
          tag_name = txt[(i+1)..(j-1)]

        else
          i += 1
          html << '['
          next
        end

        tag_name.strip!
        tag_name.downcase!

        if @@parser_modules[tag_name]
          instance_exec tag_name, arg, html, &@@parser_modules[tag_name][:html]
          i = j
        else
          html << '['
        end

      else
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

  def message_to_txt(msg)
    quote_char = uconf('quote_char', '> ')

    txt     = ""
    quotes  = 0
    max_len = msg.length
    i       = 0

    while i < max_len
      c = msg[i]

      case c
      when CfMessage::QUOTE_CHAR
        txt << quote_char

      # possible that we got a tag, check for it
      when '['
        j = i

        tag_name = ""
        arg      = ""

        while j < max_len and msg[j] != ':' and msg[j] != ']'
          j += 1
        end

        tag_name = msg[(i+1)..(j-1)] if msg[j] == ':' or msg[j] == ']'

        if msg[j] == ':'
          old = j
          while j < max_len and msg[j] != ']'
            j += 1
          end

          if msg[j] != ']'
            i += 1
            txt << '['
            next
          end

          arg = msg[(old+1)..(j-1)]

        elsif msg[j] == ']'
          tag_name = msg[(i+1)..(j-1)]

        else
          i += 1
          txt << '['
          next
        end

        tag_name.strip!
        tag_name.downcase!

        if @@parser_modules[tag_name]
          @@parser_modules[tag_name][:txt].call(tag_name, arg, txt)
          i = j
        else
          txt << '['
        end

      else
        txt << c
      end

      i += 1
    end

    txt
  end

  def quote_content(msg, quote_char)
    msg = quote_char + message_to_txt(msg).gsub(/\n/, "\n" + quote_char)

    if uconf('quote_signature', 'no') != 'yes'
      sig_pos = msg.rindex("\n-- \n")
      msg = msg[0..(sig_pos-1)] unless sig_pos.nil?
    end

    msg
  end

  def content_to_internal(msg, quote_char)
    msg = msg.gsub Regexp.new('^(' + quote_char + ')+', Regexp::MULTILINE) do |data|
      CfMessage::QUOTE_CHAR * (data.length / quote_char.length)
    end

    msg.gsub! /\r\n|\n|\r/, "\n"
    msg
  end

  # TODO: better method to load plugins, eval()ing them every time sucks
  def read_syntax_plugins
    # read syntax plugins
    plugin_dir = Rails.root + 'lib/plugins/syntax'
    Dir.open(plugin_dir).each do |p|
      next unless File.file?(plugin_dir + p)
      load Rails.root + 'lib/plugins/syntax/' + p
    end
  end
end

# eof