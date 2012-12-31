# -*- coding: utf-8 -*-

module ParserHelper
  @@parser_modules = {}

  def self.parser_modules
    @@parser_modules
  end

  def parse_args(argstr)
    if argstr[0] == '='
      argstr[1..-1]
    else
      args = argstr.split(' ')
      map = {}
      args.each do |a|
        key, value = a.split('=', 2)
        map[key] = value
      end

      map
    end
  end

  def parse_tag_name(txt, tag_name, i, closed = false)
    i += 1 if txt[i] == '['

    if txt[i] == '/'
      return if not closed
      i += 1
    else
      return if closed
    end

    j = i
    max_len = txt.length

    # find end of the tag: a tag may only consist of alnums
    while j < max_len and txt[j] =~ /[a-zA-Z0-9]/
      j += 1
    end

    if closed
      if txt[j] == ']'
        tag_name << txt[i..(j-1)]
        tag_name.strip!
        tag_name.downcase!

        return j
      end
    else
      if txt[j] == ' ' or txt[j] == ']' or txt[j] == '='
        tag_name << txt[i..(j-1)]
        tag_name.strip!
        tag_name.downcase!

        return j
      end
    end

    nil
  end

  def parse_tag(txt, html, i, format = :html)
    tag_name = ""
    args     = nil

    j = parse_tag_name(txt, tag_name, i)

    # end of tag name: what now may come are either ], = or whitespaces
    if j and (txt[j] == ' ' or txt[j] == ']' or txt[j] == '=') and @@parser_modules[tag_name]
      old = j
      if txt[j] == ' ' || txt[j] == '=' and not tag_name.blank?
        max_len = txt.length
        while j < max_len and txt[j] != ']' and txt[j] != "\n" and txt[j] != "\n"
          j += 1
        end
      end

      # if end of tag found: seems to be valid enough to do the effort of parsing the args
      if txt[j] == ']' and j > old
        args = parse_args(txt[old..(j-1)])

      elsif txt[j] != ']'
        html << '['
        return i
      end

      # recursive algorithm: find end
      content = ""
      if format == :html
        k = message_to_html_internal(txt[(j+1)..-1], content, tag_name)
      else
        k = message_to_txt_internal(txt[(j+1)..-1], content, tag_name)
      end

      if k
        instance_exec tag_name, args, content, html, &@@parser_modules[tag_name][format == :html ? :html : :txt]
        i = j + k + 1
      end
    else
      html << '['
      return i
    end

    i
  end

  def next_is(txt, i, c)
    txt.length > i + 1 && c == txt[i + 1]
  end

  def message_to_html_internal(txt, html, return_on = nil)
    quote_char = encode_entities(uconf('quote_char', '> '))

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
        html << '</span>' * quotes
        quotes = 0
        #html << "<br>\n"
        html << "\n"

      when CfMessage::QUOTE_CHAR
        html << '<span class="q"> ' + quote_char
        quotes += 1

      # possible that we got a tag, check for it
      when '['
        if next_is(txt, i, '/')
          tag_name = ""
          if j = parse_tag_name(txt, tag_name, i, true) and tag_name == return_on
            return j
          else
            html << '['
          end
        else
          i = parse_tag(txt, html, i)
        end

      else
        html << c
      end

      i += 1
    end

    html.gsub! /([[:space:]]{2,})/ do |spaces|
      '&nbsp;' * spaces.length
    end

    html.gsub! /\n/, "<br>"

    # search for the last signature
    sig_pos = html.rindex("<br>\n-- <br>\n")
    unless sig_pos.nil?
      html = html[0..(sig_pos-1)] + "<span class=\"signature\">" + html[sig_pos..-1] + "</span>"
    end

    i
  end

  def message_to_html(txt)
    html = ""
    message_to_html_internal(txt, html)
    html.html_safe
  end

  def message_to_txt(msg)
    txt = ""
    message_to_txt_internal(msg, txt)
    txt
  end

  def message_to_txt_internal(txt, html, return_on = nil)
    quote_char = uconf('quote_char', '> ')

    quotes  = 0
    max_len = txt.length
    i       = 0

    while i < max_len
      c = txt[i]

      case c
      when CfMessage::QUOTE_CHAR
        txt << quote_char

      # possible that we got a tag, check for it
      when '['
        if next_is(txt, i, '/')
          tag_name = ""
          if j = parse_tag_name(txt, tag_name, i, true) and tag_name == return_on
            return j
          else
            html << '['
          end
        else
          i = parse_tag(txt, html, i, :txt)
        end

      else
        html << c
      end

      i += 1
    end

    i
  end

  def quote_content(msg, quote_char)
    msg = message_to_txt(msg)

    if uconf('quote_signature', 'no') != 'yes'
      sig_pos = msg.rindex("\n-- \n")
      msg = msg[0..(sig_pos-1)] unless sig_pos.nil?
    end

    quote_char + msg.gsub(/\n/, "\n" + quote_char)
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
