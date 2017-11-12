require 'kramdown'

class Kramdown::Parser::CfMarkdown < Kramdown::Parser::Kramdown
  @@parsers.delete :block_html
  @@parsers.delete :span_html
  @@parsers.delete :setext_header
  @@parsers.delete :typographic_syms
  @@parsers.delete :smart_quotes
  @@parsers.delete :escaped_chars

  def initialize(*args)
    super(*args)

    @block_parsers.unshift :email_style_sig
    @span_parsers.unshift :email_style_sig_span
    @span_parsers.unshift :inline_strikethrough

    idx = @block_parsers.index(:setext_header)
    @block_parsers[idx] = :cf_setext_header
    @app_controller = args.last[:app]
    @with_styles = args.last[:with_styles]
  end

  Kernel.silence_warnings do
    ESCAPED_CHARS = /\\([\\.*_+`<>()\[\]{}#!:|"'\$=~-])/
    CF_SETEXT_HEADER_START = /^(#{OPT_SPACE}[^ \t].*?)#{HEADER_ID}[ \t]*?\n(-|=)+\n/
    FENCED_CODEBLOCK_MATCH = /^((~){3,})\s*?((\S+?)(?:\?\S*)?)?\s*?(?:,\s*?(good|bad)\s*?)?\n(.*?)^\1\2*\s*?\n/m
  end

  define_parser(:escaped_chars, ESCAPED_CHARS, '\\\\') unless @@parsers.key?(:escaped_chars)
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

  Kernel.silence_warnings do
    INLINE_STRIKE_THROUGH_START = /~~(?!~)/m
  end
  def parse_inline_strikethrough
    start_line_number = @src.current_line_number
    @src.scan(/~~/)
    saved_pos = @src.save_pos

    if @src.pre_match =~ /~\Z/
      add_text('~~')
      return
    end

    text = @src.scan_until(/~~/)
    if text
      text.sub!(/~~\Z/, '')
      text.strip!
      @tree.children << Element.new(:strike_through, text, nil,
                                    category: :span, location: start_line_number)
    else
      @src.revert_pos(saved_pos)
      add_text('~~')
    end
  end
  define_parser(:inline_strikethrough, INLINE_STRIKE_THROUGH_START, '~') unless @@parsers.key?(:inline_strikethrough)

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

  def parse_attribute_list(str, opts)
    return if str.strip.empty? || str.strip == ':'
    my_opts = {}

    if str =~ /@([a-zA-Z_-]+)/
      my_opts['lang'] = Regexp.last_match(1)
      str = str.gsub(/@([a-zA-Z_-]+)/, '')
    end

    super(str, opts)

    opts.merge!(my_opts)
  end

  def parse_codeblock_fenced
    if @src.check(self.class::FENCED_CODEBLOCK_MATCH)
      start_line_number = @src.current_line_number
      @src.pos += @src.matched_size
      el = new_block_el(:codeblock, @src[6], nil, location: start_line_number)
      lang = @src[3].to_s.strip
      good_bad = @src[5].to_s.strip

      unless lang.empty?
        el.options[:lang] = lang
        el.attr['class'] = "language-#{@src[4]}"
      end

      unless good_bad.empty?
        el.attr['class'] = (el.attr['class'].to_s + ' ' + good_bad).strip
      end

      @tree.children << el

      true
    else
      false
    end
  end

  def update_attr_with_ial(attr, ial)
    if ial[:refs]
      ial[:refs].each do |ref|
        ref = @alds[ref]
        update_attr_with_ial(attr, ref) if ref
      end
    end

    ial.each do |k, v|
      next if k =~ /^on.*/
      next if k == 'style' && !@with_styles

      if k == IAL_CLASS_ATTR
        attr[k] = (attr[k] || '') << " #{v}"
        attr[k].lstrip!
      elsif k.is_a?(String)
        attr[k] = v
      end
    end
  end
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
  include LinksHelper

  @@language_replacements = { 'svg' => 'xml', 'html5' => 'html' }

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
    code = pygmentize(el.value, @@language_replacements[lang] || lang)

    attr['class'] = (attr['class'].to_s + " block language-#{lang}").strip
    "#{' ' * indent}<code#{html_attributes(attr)}>#{code}</code>\n"
  end

  def convert_codespan(el, _indent)
    attr = el.attr.dup
    lang = extract_code_language!(attr) || @options[:kramdown_default_lang]
    code = pygmentize(el.value, @@language_replacements[lang] || lang)

    attr['class'] = (attr['class'].to_s + " language-#{lang}").strip if lang
    "<code#{html_attributes(attr)}>#{code}</code>"
  end

  def convert_email_style_sig(el, indent)
    @sig_content = '<span class="signature"><span class="sig-dashes">-- </span>' + inner(el, indent) + '</span>'
    ''
  end

  def convert_strike_through(el, indent)
    attr = el.attr.dup
    attr['class'] = attr['class'].to_s + ' strike-through'

    "#{' ' * indent}<del#{html_attributes(attr)}>" + escape_html(el.value) + '</del>'
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
      if (@options[:root_url].blank? || !el.attr['href'].start_with?(@options[:root_url])) && !url_whitelisted?(el.attr['href'])
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
