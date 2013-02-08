# -*- coding: utf-8 -*-

require 'kramdown'

class Kramdown::Parser::CfMarkdown < Kramdown::Parser::Kramdown
  def parse_block_html
    false
  end

  def parse_span_html
    add_text(@src.getch)
  end
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
  def convert_codeblock(el, indent)
    ret = super(el, indent)

    ret.gsub! /^<div>(.*)<\/div>/m, '\1'
    '<code><pre>' + ret + '</pre></code>'
  end

end

# eof
