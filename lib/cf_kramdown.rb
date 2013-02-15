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

    @block_parsers.unshift :email_style_sig
    @span_parsers.unshift :email_style_sig
  end

  CF_SETEXT_HEADER_START = /^(#{OPT_SPACE}[^ \t].*?)#{HEADER_ID}[ \t]*?\n(-|=)+\n/
  @@parsers.delete(:setext_header)
  define_parser(:setext_header, CF_SETEXT_HEADER_START)

  SIGNATURE_START = /^-- \n/
  def parse_email_style_sig
    @src.pos += @src.matched_size
    el = new_block_el(:email_style_sig)

    @tree.children << el
    parse_spans(el)

    true
  end
  define_parser(:email_style_sig, SIGNATURE_START) unless @@parsers.has_key?(:email_style_sig)
end

class Kramdown::Converter::CfHtml < Kramdown::Converter::Html
  def convert_codeblock(el, indent)
    ret = super(el, indent)

    ret.gsub! /^<div>(.*)<\/div>/m, '\1'
    '<code><pre>' + ret + '</pre></code>'
  end

  def convert_email_style_sig(el, indent)
    "<span class=\"signature\"><br />\n-- <br />\n" + inner(el, indent) + "</span>"
  end

end

# eof
