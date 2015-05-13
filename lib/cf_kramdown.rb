# -*- coding: utf-8 -*-

require 'kramdown'

class Kramdown::Parser::CfMarkdown < Kramdown::Parser::Kramdown
  @@parsers.delete :block_html
  @@parsers.delete :span_html
  @@parsers.delete :setext_header
  @@parsers.delete :typographic_syms
  @@parsers.delete :smart_quotes

  def initialize(*args)
    super(*args)

    @block_parsers.unshift :email_style_sig
    @span_parsers.unshift :email_style_sig_span

    idx = @block_parsers.index(:setext_header)
    @block_parsers[idx] = :cf_setext_header
  end

  Kernel::silence_warnings {
    CF_SETEXT_HEADER_START = /^(#{OPT_SPACE}[^ \t].*?)#{HEADER_ID}[ \t]*?\n(-|=)+\n/
  }
  define_parser(:cf_setext_header, CF_SETEXT_HEADER_START)  unless @@parsers.has_key?(:cf_setext_header)
  alias_method :parse_cf_setext_header, :parse_setext_header

  Kernel::silence_warnings {
    SIGNATURE_START = /^-- \n/
  }
  def parse_email_style_sig
    @src.pos += @src.matched_size
    result = @src.scan(/.*/m)

    el = new_block_el(:email_style_sig)

    @tree.children << el
    add_text(result, el)

    true
  end
  define_parser(:email_style_sig, SIGNATURE_START) unless @@parsers.has_key?(:email_style_sig)


  def parse_email_style_sig_span
    @src.pos += @src.matched_size
    el = new_block_el(:email_style_sig)
    @tree.children << el
    parse_spans(el)

    true
  end
  define_parser(:email_style_sig_span, SIGNATURE_START) unless @@parsers.has_key?(:email_style_sig_span)

  define_parser(:span_html, /\0/) unless @@parsers.has_key?(:pan_html)
  define_parser(:block_html, /\0/) unless @@parsers.has_key?(:block_html)
  define_parser(:smart_quotes, /\0/) unless @@parsers.has_key?(:smart_quotes)
  define_parser(:typographic_syms, /\0/) unless @@parsers.has_key?(:typographic_syms)

  def parse_html_entity
    start_line_number = @src.current_line_number
    @src.pos += @src.matched_size

    @tree.children << Element.new(:entity, ::Kramdown::Utils::Entities.entity('amp'),
                                  nil, location: start_line_number)
    add_text(@src.matched[1..-1])
  end

  def handle_extension(name, opts, body, type, line_no = nil)
    if name == 'nomarkdown'
      add_text(body) if body.kind_of?(String)
      true
    else
      super(name, opts, body, type, line_no)
    end
  end
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
  def initialize(*args)
    super(*args)
    @indent = 0
  end

  def convert_codeblock(el, indent)
    ret = super(el, indent)
    ret.gsub!(/^(\s*)<div[^>]*>\n?(.*)<\/div>/m, '\1<code class="block">\2</code>')
    ret.gsub!(/<pre><code>(.*)<\/code><\/pre>/m, '<code class="block">\1</code>')

    ret
  end

  def convert_email_style_sig(el, indent)
    "<span class=\"signature\"><br />\n-- <br />\n" + inner(el, indent) + "</span>"
  end

  def convert_a(el, indent)
    if @options[:no_follow]
      if @options[:root_url].blank? or not el.attr['href'].start_with?(@options[:root_url])
        el.attr['rel'] = 'nofollow'
      end
    end
    super(el, indent)
  end

  def convert_footnote(el, indent)
    ret = super(el, indent)
    ret = ret.gsub(/fnref:/, @options[:auto_id_prefix] + 'fnref:')
    ret.gsub(/#fn:/, '#' + @options[:auto_id_prefix] + 'fn:')
  end

  def footnote_content
    footnote_backlink_fmt = "%s<a href=\"#" + @options[:auto_id_prefix] + "fnref:%s\" class=\"reversefootnote\">%s</a>"

    ol = Kramdown::Element.new(:ol)
    ol.attr['start'] = @footnote_start if @footnote_start != 1
    i = 0
    while i < @footnotes.length
      name, data, _, repeat = *@footnotes[i]
      li = Kramdown::Element.new(:li, nil, {'id' => @options[:auto_id_prefix] + "fn:#{name}"})
      li.children = Marshal.load(Marshal.dump(data.children))

      if li.children.last.type == :p
        para = li.children.last
        insert_space = true
      else
        li.children << (para = Kramdown::Element.new(:p))
        insert_space = false
      end

      para.children << Kramdown::Element.new(:raw, footnote_backlink_fmt % [insert_space ? ' ' : '', name, "&#8617;"])
      (1..repeat).each do |index|
        para.children << Kramdown::Element.new(:raw, footnote_backlink_fmt % [" ", "#{name}:#{index}", "&#8617;<sup>#{index+1}</sup>"])
      end

      ol.children << Kramdown::Element.new(:raw, convert(li, 4))
      i += 1
    end
    (ol.children.empty? ? '' : format_as_indented_block_html('div', {:class => "footnotes"}, convert(ol, 2), 0))
  end
end

# eof
