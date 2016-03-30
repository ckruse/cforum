# -*- coding: utf-8 -*-

require 'strscan'

module CforumMarkup
  def cforum2markdown(content)
    content = content.gsub(/&#160;/, ' ')
    content.gsub!(/\[\/?latex\]/, '$$')
    doc = StringScanner.new(content)
    ncnt = ''
    coder = HTMLEntities.new
    code_open = 0
    in_quote = 0
    in_math = false
    consecutive_newlines = 0
    code_stack = []

    while !doc.eos?
      if doc.scan(/<br \/>-- <br \/>/)
        ncnt << "\n-- \n"
        in_quote = 0
        consecutive_newlines = 1

      elsif doc.scan(/\$\$/)
        in_math = !in_math
        ncnt << doc.matched
        consecutive_newlines = 0

      elsif doc.scan(/(<br \/>|^)([\s ]*)#/)
        if $1 == "<br />"
          ncnt << "\n"
          in_quote = 0
          consecutive_newlines += 1
        end

        ncnt << $2.to_s + (code_open > 0 ? "#" : '\\#')

      elsif doc.scan(/<br \/>/)
        in_quote = 0
        consecutive_newlines += 1

        if doc.matched.length / 6 > 1
          ncnt << "\n" * (doc.matched.length / 6)
        else
          ncnt << "  \n"
        end

      elsif doc.scan(/\u007F/)
        ncnt << '> '
        in_quote += 1

      elsif doc.scan(/(-{2,})|\*|_/)
        ncnt << '\\' if code_open <= 0 and not in_math
        ncnt << doc.matched
        consecutive_newlines = 0

      elsif doc.scan(/<img[^>]+>/)
        consecutive_newlines = 0

        data = doc.matched
        alt = ""
        src = ""

        src = $1 if data =~ /src="([^"]+)"/
        alt = $1 if data =~ /alt="([^"]+)"/

        alt = src if alt.blank?

        ncnt << "![#{alt}](#{src})"

      elsif doc.scan(/\[(\w+):?/i)
        save = doc.pos
        directive = doc[1]
        content = ''
        no_end = true
        colon = doc.matched[-1] == ':' ? ':' : ''

        doc.skip(/\s/)

        while no_end and not doc.eos?
          content << doc.matched if doc.scan(/[^\]\\]/)

          if doc.scan(/\\\]/)
            content << '\]'
          elsif doc.scan(/\\/)
            content << "\\"
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
        if doc.eos? and no_end
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
                    "\n" + ("> " * in_quote) + "\n" + ("> " * in_quote) + "~~~"
                  else
                    #raise "ho" + consecutive_newlines.inspect + "\n" + ncnt.inspect if ncnt =~ /&quot;valider&quot;\?\n\n~~~/
                    '~~~'
                  end

            unless content.blank?
              _, lang = content.split(/=/, 2)
              val << ' ' + lang unless lang.blank?
            end

            val << "\n"
            val << ("> " * in_quote) unless doc.scan(/\s*<br \/>/)

            code_stack << [ncnt, val, lang]
            ncnt = ''
          end

          code_open += 1
        end

        consecutive_newlines = 0

      elsif doc.scan(/\[code\]/)
        ncnt << "~~~" if code_open <= 0
        code_open += 1

      elsif doc.scan(/\[\/code\]/)
        if code_open > 0
          top = code_stack.pop

          if ncnt =~ /\n/
            ncnt = top[0] + top[1] + ncnt + "\n" + ("> " * in_quote) + "~~~"
          else
            ncnt = top[0] + "`" + ncnt + "`"
            ncnt << '{:.language-' + top[2] + '}' unless top[2].blank?
          end

          code_open -= 1
        else
          ncnt << '[/code]'
        end

      elsif doc.scan(/\|/)
        ncnt << '\\' if code_open == 0
        ncnt << '|'

      else
        ncnt << doc.matched if doc.scan(/./m)
      end
    end

    # broken cforum markup
    unless code_stack.blank?
      while top = code_stack.pop
        ncnt = top[0] + '[code' + (top[2].blank? ? ']' : ' lang=' + top[2] + ']') + ncnt
      end
    end

    cnt = ''
    ncnt.lines.each_with_index do |l,i|
      if l =~ /^(?:(> )*)~~~/ and i > 0
        q = $1
        if ncnt.lines[i - 1] !~ /^(> )*$/
          cnt << "#{q}\n"
        end
      end

      cnt << l
    end

    cnt.gsub!(/^[[:blank:]]+~~~/, "~~~")
    cnt.gsub!(/~~~\n(.*)\n~~~/, '`\1`')
    cnt.gsub!(/~~~[[:blank:]]*(\w+)\n(.*)\n~~~/, '`\2`{: .language-\1}')
    #cnt.gsub!(/(?<!\n\n)~~~(.*?)~~~/m, "\n\n~~~\\1~~~")

    coder.decode(cnt)
  end

  def cforum_gen_pref(href)
    orig = href
    href, title = href.split('@title=', 2) if href =~ /@title=/
    t, m = href.split(/(&amp)?;/)

    return '[pref:' + orig + ']' if t.blank? or m.blank?

    '[' + (title.blank? ? ('?' + t + '&' + m) : title) + '](/?' + t + "&" + m + ')'
  end

  def cforum_gen_image(href)
    href, title = href.split('@title=', 2) if href =~ /@title=/
    '![' + (title.blank? ? href : title) + "](#{href})"
  end

  def cforum_gen_link(directive, content)
    title = href = nil

    if directive == 'ref'
      ref, href = content.split(';', 2)
      href, title = href.split('@title=', 2) if href =~ /@title=/

      if %w(self8 self81 self811 self812 sel811 sef811 slef812).include?(ref)
        href = "http://de.selfhtml.org/#{href}"
      elsif ref == 'self7'
        href = "http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href})"
      elsif ref == 'zitat'
        href = "http://community.de.selfhtml.org/zitatesammlung/zitat#{href})"
      else
        return nil
      end

    elsif directive == 'link'
      href = content
      href, title = href.split('@title=', 2) if href =~ /@title=/
    end

    return nil if href.blank?

    '[' + (title.blank? ? href : title) + "](#{href})"
  end
end

# eof
