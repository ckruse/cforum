# -*- coding: utf-8 -*-

require 'markdown'

class CfMarkdown < Kramdown::Parser::Kramdown
  def parse_block_html
    false
  end

  def parse_span_html
    add_text(@src.getch)
  end
end

# eof
