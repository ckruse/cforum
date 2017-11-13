require 'strscan'

module CforumMarkup
  def cforum2markdown(document_content)
    document_content = document_content.gsub(/&#160;/, ' ')
    document_content.gsub!(%r{\[/?latex\]}, '$$')
    doc = StringScanner.new(document_content)
    ncnt = ''
    coder = HTMLEntities.new
    code_open = 0
    in_quote = 0
    in_math = false
    consecutive_newlines = 0
    code_stack = []

    until doc.eos?
      if doc.scan(%r{<br ?/>-- <br ?/>})
        ncnt << "\n-- \n"
        in_quote = 0
        consecutive_newlines = 1

      elsif doc.scan(/\$\$/)
        in_math = !in_math
        ncnt << doc.matched
        consecutive_newlines = 0

      elsif doc.scan(%r{(<br ?/>|^)([\s ]*)#})
        matched = doc.matched

        if matched =~ %r{^<br ?/>}
          ncnt << "\n"
          in_quote = 0
          consecutive_newlines += 1
          matched = matched.gsub(%r{^<br ?/>}, '')
        end

        ncnt << matched.gsub(/#\Z/, '') + (code_open.positive? ? '#' : '\\#')

      elsif doc.scan(%r{(?:<br ?/>)+})
        in_quote = 0
        consecutive_newlines += 1
        size = doc.matched.scan(%r{<br ?/>}).size

        ncnt << if size > 1
                  "\n" * size
                else
                  "  \n"
                end

      elsif doc.scan(/\u007F/)
        ncnt << '> '
        in_quote += 1

      elsif doc.scan(/(-{2,})|\*|_/)
        ncnt << '\\' if (code_open <= 0) && !in_math
        ncnt << doc.matched
        consecutive_newlines = 0

      elsif doc.scan(/~/)
        ncnt << '\\~'
        consecutive_newlines = 0

      elsif doc.scan(/<img[^>]+>/)
        consecutive_newlines = 0

        data = doc.matched
        alt = ''
        src = ''

        src = Regexp.last_match(1) if data =~ /src="([^"]+)"/
        alt = Regexp.last_match(1) if data =~ /alt="([^"]+)"/ # rubocop:disable Performance/RegexpMatch

        alt = '' if alt.blank?

        ncnt << "![#{alt}](#{src})"

      elsif doc.scan(/\[(\w+):?/i)
        save = doc.pos
        directive = doc[1]
        content = ''
        no_end = true
        colon = doc.matched[-1] == ':' ? ':' : ''

        doc.skip(/\s/)

        while no_end && !doc.eos?
          content << doc.matched if doc.scan(/[^\]\\]/)

          if doc.scan(/\\\]/)
            content << '\]'
          elsif doc.scan(/\\/)
            content << '\\'
          elsif doc.scan(/\]/)
            no_end = false
          end
        end

        # empty directive
        if directive.blank?
          ncnt << "[#{directive}#{colon}"
          doc.pos = save
          consecutive_newlines = 0
          next
        end

        # unterminated directive
        if doc.eos? && no_end
          ncnt << "[#{directive}#{colon}"
          doc.pos = save
          consecutive_newlines = 0
          next
        end

        case directive
        when 'link', 'ref'
          val = cforum_gen_link(directive, content)
          if val.blank?
            ncnt << "[#{directive}#{colon}"
            doc.pos = save
            consecutive_newlines = 0
            next
          end

          ncnt << val

        when 'image'
          ncnt << cforum_gen_image(content)

        when 'pref'
          ncnt << cforum_gen_pref(content)

        when 'code'
          if code_open <= 0
            val = if consecutive_newlines < 2
                    "\n" + ('> ' * in_quote) + "\n" + ('> ' * in_quote) + '~~~'
                  else
                    '~~~'
                  end

            if content.present?
              _, lang = content.split(/=/, 2)
              val << ' ' + lang if lang.present?
            end

            val << "\n"
            val << ('> ' * in_quote) unless doc.scan(%r{\s*<br ?/>})

            code_stack << [ncnt, val, lang]
            ncnt = ''
          end

          code_open += 1
        else
          ncnt << "[#{directive}#{colon}"
          doc.pos = save
          consecutive_newlines = 0
          next
        end

        consecutive_newlines = 0

      elsif doc.scan(%r{\[/code\]})
        if code_open.positive?
          if code_open <= 1 # only close code when this [/code] is the last one
            top = code_stack.pop

            if top.present? # broken markup
              if ncnt.match?(/\n/)
                ncnt = top[0] + top[1] + ncnt + "\n" + ('> ' * in_quote) + '~~~'
                2.times { doc.scan(%r{<br ?/>}) } # eat up following newlines
                ncnt << "\n\n"
              else
                ncnt = top[0] + '`' + ncnt + '`'
                ncnt << '{:.language-' + top[2] + '}' if top[2].present?
              end
            end
          end

          code_open -= 1
        else
          ncnt << '[/code]'
        end

      elsif doc.scan(/\|/)
        ncnt << '\\' if code_open.zero?
        ncnt << '|'

      elsif doc.scan(/./m)
        ncnt << doc.matched
      end
    end

    # broken cforum markup
    if code_stack.present?
      while (top = code_stack.pop)
        ncnt = top[0] + '[code' + (top[2].blank? ? ']' : ' lang=' + top[2] + ']') + ncnt
      end
    end

    cnt = ''
    ncnt.lines.each_with_index do |l, i|
      if l =~ /^(?:(> )*)~~~/ && i.positive?
        q = Regexp.last_match(1)
        cnt << "#{q}\n" if ncnt.lines[i - 1] !~ /^(> )*$/
      end

      cnt << l
    end

    cnt.gsub!(/^[[:blank:]]+~~~/, '~~~')
    cnt.gsub!(/~~~\n(.*)\n~~~/, '`\1`')
    cnt.gsub!(/~~~[[:blank:]]*(\w+)\n(.*)\n~~~/, '`\2`{: .language-\1}')
    # cnt.gsub!(/(?<!\n\n)~~~(.*?)~~~/m, "\n\n~~~\\1~~~")

    coder.decode(cnt)
  end

  def cforum_gen_pref(href)
    orig = href
    href, title = href.split('@title=', 2) if href.match?(/@title=/)
    t, m = href.split(/(?:&amp)?;/)

    return '[pref:' + orig + ']' if t.blank? || m.blank?

    '[' + (title.blank? ? ('?' + t + '&' + m) : title) + '](/?' + t + '&' + m + ')'
  end

  def cforum_gen_image(href)
    href, title = href.split('@alt=', 2)
    '![' + (title.blank? ? '' : title) + "](#{href})"
  end

  def cforum_gen_link(directive, content)
    title = href = nil

    if directive == 'ref'
      ref, href = content.split(';', 2)
      href, title = href.split('@title=', 2) if href.present? && href.match?(/@title=/)

      if %w[self8 self81 self811 self812 sel811 sef811 slef812].include?(ref)
        href = "http://de.selfhtml.org/#{href}"
      elsif ref == 'self7'
        href = "http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href}"
      elsif ref == 'zitat'
        href = "/cites/old/#{href}"
      else
        return nil
      end

    elsif directive == 'link'
      href = content
      href, title = href.split('@title=', 2) if href.match?(/@title=/)
    end

    return nil if href.blank?

    '[' + (title.blank? ? href : title) + "](#{href})"
  end
end

# eof
