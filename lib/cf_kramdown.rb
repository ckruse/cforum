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
    @app_controller = args.last[:app]
  end

  Kernel.silence_warnings do
    CF_SETEXT_HEADER_START = /^(#{OPT_SPACE}[^ \t].*?)#{HEADER_ID}[ \t]*?\n(-|=)+\n/
  end
  define_parser(:cf_setext_header, CF_SETEXT_HEADER_START) unless @@parsers.key?(:cf_setext_header)
  alias parse_cf_setext_header parse_setext_header

  Kernel.silence_warnings do
    SIGNATURE_START = /^-- \n/
  end
  def parse_email_style_sig
    @src.pos += @src.matched_size
    result = @src.scan(/.*/m)

    el = new_block_el(:email_style_sig)

    @tree.children << el
    add_text(result, el)

    true
  end
  define_parser(:email_style_sig, SIGNATURE_START) unless @@parsers.key?(:email_style_sig)

  def parse_email_style_sig_span
    @src.pos += @src.matched_size
    el = new_block_el(:email_style_sig)
    @tree.children << el
    parse_spans(el)

    true
  end
  define_parser(:email_style_sig_span, SIGNATURE_START) unless @@parsers.key?(:email_style_sig_span)

  define_parser(:span_html, /\0/) unless @@parsers.key?(:span_html)
  define_parser(:block_html, /\0/) unless @@parsers.key?(:block_html)
  define_parser(:smart_quotes, /\0/) unless @@parsers.key?(:smart_quotes)
  define_parser(:typographic_syms, /\0/) unless @@parsers.key?(:typographic_syms)

  def parse_html_entity
    start_line_number = @src.current_line_number
    @src.pos += @src.matched_size

    @tree.children << Element.new(:entity, ::Kramdown::Utils::Entities.entity('amp'),
                                  nil, location: start_line_number)
    add_text(@src.matched[1..-1])
  end

  def handle_extension(name, opts, body, type, line_no = nil)
    if name == 'nomarkdown'
      add_text(body) if body.is_a?(String)
      true
    else
      super(name, opts, body, type, line_no)
    end
  end
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
  include LinksHelper

  def initialize(*args)
    super(*args)
    @indent = 0
    @sig_content = nil
    @app = args.last.is_a?(Hash) ? args.last[:app] : nil
    @config_manager = ConfigManager.new if @app.nil?
  end

  def conf(name)
    return @app.conf(name) if @app
    @config_manager.get(name, nil, nil)
  end

  def convert_codeblock(el, indent)
    attr = el.attr.dup
    lang = extract_code_language!(attr) || @options[:kramdown_default_lang]
    code = pygmentize(el.value, lang)

    attr['class'] = (attr['class'].to_s + " block language-#{lang}").strip
    "#{' ' * indent}<code#{html_attributes(attr)}>#{code}</code>\n"
  end

  def convert_codespan(el, _indent)
    attr = el.attr.dup
    lang = extract_code_language!(attr) || @options[:kramdown_default_lang]
    code = pygmentize(el.value, lang)
    attr['class'] = (attr['class'].to_s + " language-#{lang}").strip if lang
    "<code#{html_attributes(attr)}>#{code}</code>"
  end

  def convert_email_style_sig(el, indent)
    @sig_content = '<span class="signature"><span class="sig-dashes">-- </span>' + inner(el, indent) + '</span>'
    ''
  end

  def convert_a(el, indent)
    @entity_decoder ||= HTMLEntities.new
    href = @entity_decoder.decode(el.attr['href'])
    if href.downcase.gsub(/[\s\0-\32]/u, '').start_with?('javascript:')
      res = inner(el, indent)
      res1 = escape_html(el.attr['href'])
      return "[#{res}](#{res1})"
    end

    if @options[:no_follow]
      if (@options[:root_url].blank? || !el.attr['href'].start_with?(@options[:root_url])) && !is_url_whitelisted?(el.attr['href'])
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
    footnote_backlink_fmt = '%s<a href="#' + @options[:auto_id_prefix] + 'fnref:%s" class="reversefootnote">%s</a>'

    ol = Kramdown::Element.new(:ol)
    ol.attr['start'] = @footnote_start if @footnote_start != 1
    i = 0
    while i < @footnotes.length
      name, data, _, repeat = *@footnotes[i]
      li = Kramdown::Element.new(:li, nil, 'id' => @options[:auto_id_prefix] + "fn:#{name}")
      li.children = Marshal.load(Marshal.dump(data.children))

      if li.children.last.type == :p
        para = li.children.last
        insert_space = true
      else
        li.children << (para = Kramdown::Element.new(:p))
        insert_space = false
      end

      para.children << Kramdown::Element.new(:raw, footnote_backlink_fmt % [insert_space ? ' ' : '', name, '&#8617;'])
      (1..repeat).each do |index|
        para.children << Kramdown::Element.new(:raw, footnote_backlink_fmt % [' ', "#{name}:#{index}", "&#8617;<sup>#{index + 1}</sup>"])
      end

      ol.children << Kramdown::Element.new(:raw, convert(li, 4))
      i += 1
    end

    content = (ol.children.empty? ? '' : format_as_indented_block_html('div', { class: 'footnotes' }, convert(ol, 2), 0))
    content + @sig_content.to_s
  end

  def pygmentize(code, lang)
    if lang
      Pygments.highlight(code,
                         lexer: lang,
                         options: { startinline: true, encoding: 'utf-8', nowrap: true })
    else
      escape_html(code)
    end
  rescue MentosError
    escape_html(code)
  end
end

# eof
