require 'kramdown/parser'
require 'kramdown/converter'
require 'kramdown/utils'

class Kramdown::Converter::Plain < Kramdown::Converter::Base
  def initialize(root, options)
    super
    @footnote_counter = @footnote_start = @options[:footnote_nr]
    @footnotes = []
    @footnotes_by_name = {}
    @footnote_location = nil
    @toc = []
    @toc_code = nil
    @stack = []
  end

  def plain(text)
    text.to_s.gsub(/[ <>&]/, ' ')
  end

  # The mapping of element type to conversion method.
  DISPATCHER = Hash.new { |h, k| h[k] = "convert_#{k}" }

  # Dispatch the conversion of the element +el+ to a +convert_TYPE+ method using the +type+ of
  # the element.
  def convert(el)
    send(DISPATCHER[el.type], el)
  end

  # Return the converted content of the children of +el+ as a string.
  #
  # Pushes +el+ onto the @stack before converting the child elements and pops it from the stack
  # afterwards.
  def inner(el)
    result = ''
    @stack.push(el)
    el.children.each do |inner_el|
      result << send(DISPATCHER[inner_el.type], inner_el)
    end
    @stack.pop
    result
  end

  def convert_blank(_el)
    ''
  end

  def convert_text(el)
    plain(el.value)
  end

  def convert_p(el)
    inner(el) + "\n\n"
  end

  def convert_codeblock(el)
    plain(el.value)
  end

  def convert_blockquote(_el)
    ''
  end

  def convert_header(el)
    inner(el)
  end

  def convert_hr(_el)
    "------------------------------------------------------------------------\n\n"
  end

  def convert_ul(el)
    inner(el)
  end
  alias convert_ol convert_ul

  def convert_dl(el)
    inner(el)
  end

  def convert_li(el)
    output = '- '
    res = inner(el)
    if el.children.empty? || (el.children.first.type == :p && el.children.first.options[:transparent])
      output << res
    else
      output << "\n" << res
    end

    output + "\n"
  end
  alias convert_dd convert_li

  def convert_dt(el)
    inner(el) + ":\n"
  end

  def convert_xml_comment(_el)
    ''
  end
  alias convert_xml_pi convert_xml_comment

  def convert_table(el)
    inner(el)
  end
  alias convert_thead convert_table
  alias convert_tbody convert_table
  alias convert_tfoot convert_table
  alias convert_tr convert_table

  def convert_td(el)
    inner(el)
  end

  def convert_comment(_el)
    ''
  end

  def convert_br(_el)
    "\n"
  end

  def convert_a(el)
    res = inner(el)

    res = if res != el.attr['href']
            res + ' ' + el.attr['href']
          else
            res
          end

    res
  end

  def convert_img(el)
    ret = el.attr['src']
    if !el.attr['alt'].empty? && (el.attr['alt'] != el.attr['src'])
      ret += ' ' + el.attr['alt']
    end

    ret
  end

  def convert_codespan(el)
    plain(el.value)
  end

  def convert_footnote(el)
    if (footnote = @footnotes_by_name[el.options[:name]])
      number = footnote[2]
      footnote[3] += 1
    else
      number = @footnote_counter
      @footnote_counter += 1
      @footnotes << [el.options[:name], el.value, number, 0]
      @footnotes_by_name[el.options[:name]] = @footnotes.last
    end

    '[' + number.to_s + ']'
  end

  def convert_raw(el)
    if el.options[:type].blank? || el.options[:type].include?('html')
      plain(el.value) + (el.options[:category] == :block ? "\n" : '')
    else
      ''
    end
  end

  def convert_em(el)
    inner(el)
  end
  alias convert_strong convert_em

  def convert_entity(el)
    el.value.name
  end

  def convert_math(el)
    plain(el.value)
  end

  def convert_abbreviation(el)
    title = @root.options[:abbrev_defs][el.value]
    ret = plain(el.value)
    ret += ' (' + title + ')' unless title.empty?

    ret
  end

  def convert_root(el)
    result = inner(el)
    if @footnote_location
      result.sub!(/#{@footnote_location}/, footnote_content)
    else
      result << footnote_content
    end
    if @toc_code
      toc_tree = generate_toc_tree(@toc, @toc_code[0], @toc_code[1] || {})
      text = if !toc_tree.children.empty?
               convert(toc_tree, 0)
             else
               ''
             end
      result.sub!(/#{@toc_code.last}/, text)
    end
    result
  end

  # Generate and return an element tree for the table of contents.
  def generate_toc_tree(toc, type, attr)
    sections = Element.new(type, nil, attr)
    sections.attr['id'] ||= 'markdown-toc'
    stack = []
    toc.each do |level, id, children|
      li = Element.new(:li, nil, nil, level: level)
      li.children << Element.new(:p, nil, nil, transparent: true)
      a = Element.new(:a, nil)
      a.attr['href'] = "##{id}"
      a.attr['id'] = "#{sections.attr['id']}-#{id}"
      a.children.concat(remove_footnotes(Marshal.load(Marshal.dump(children))))
      li.children.last.children << a
      li.children << Element.new(type)

      success = false
      until success
        if stack.empty?
          sections.children << li
          stack << li
          success = true
        elsif stack.last.options[:level] < li.options[:level]
          stack.last.children.last.children << li
          stack << li
          success = true
        else
          item = stack.pop
          item.children.pop if item.children.last.children.empty?
        end
      end
    end
    until stack.empty?
      item = stack.pop
      item.children.pop if item.children.last.children.empty?
    end
    sections
  end

  # Remove all footnotes from the given elements.
  def remove_footnotes(elements)
    elements.delete_if do |c|
      remove_footnotes(c.children)
      c.type == :footnote
    end
  end

  # Obfuscate the +text+ by using HTML entities.
  def obfuscate(text)
    result = ''
    text.each_byte do |b|
      result << (b > 128 ? b.chr : format('&#%03d;', b))
    end
    result.force_encoding(text.encoding) if result.respond_to?(:force_encoding)
    result
  end

  FOOTNOTE_BACKLINK_FMT = '%s<a href="#fnref:%s" class="reversefootnote">%s</a>'.freeze

  # Return a HTML ordered list with the footnote content for the used footnotes.
  def footnote_content
    ol = Kramdown::Element.new(:ol)
    ol.attr['start'] = @footnote_start if @footnote_start != 1
    i = 0
    while i < @footnotes.length
      name, data, _, repeat = *@footnotes[i]
      li = Kramdown::Element.new(:li, nil, 'id' => "fn:#{name}")
      li.children = Marshal.load(Marshal.dump(data.children))

      if li.children.last.type == :p
        para = li.children.last
        insert_space = true
      else
        li.children << (para = Kramdown::Element.new(:p))
        insert_space = false
      end

      para.children << Kramdown::Element.new(:raw, format(FOOTNOTE_BACKLINK_FMT, insert_space ? ' ' : '',
                                                          name, '&#8617;'))
      (1..repeat).each do |index|
        para.children << Kramdown::Element.new(:raw, format(FOOTNOTE_BACKLINK_FMT, ' ', "#{name}:#{index}",
                                                            "&#8617;<sup>#{index + 1}</sup>"))
      end

      ol.children << Kramdown::Element.new(:raw, convert(li))
      i += 1
    end
    (ol.children.empty? ? '' : convert(ol))
  end

  def convert_email_style_sig(_el)
    ''
  end

  def convert_strike_through(el)
    inner(el)
  end
end

# eof
