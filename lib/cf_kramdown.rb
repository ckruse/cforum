# -*- coding: utf-8 -*-

require 'kramdown'

class Kramdown::Parser::CfMarkdown < Kramdown::Parser::Kramdown
  @@parsers.delete :block_html
  @@parsers.delete :span_html
  @@parsers.delete :html_entity

  def initialize(*args)
    super(*args)

    @block_parsers.delete :block_html
    @span_parsers.delete :span_html
    @span_parsers.delete :html_entity
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
