# -*- coding: utf-8 -*-

require 'kramdown'

class Kramdown::Parser::CfMarkdown < Kramdown::Parser::Kramdown
  @@parsers.delete :block_html
  @@parsers.delete :span_html
  @@parsers.delete :html_entity
  @@parsers.delete :setext_header

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
  define_parser(:html_entity, /\0/) unless @@parsers.has_key?(:html_entity)
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
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
end

# eof
