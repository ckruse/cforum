# -*- coding: utf-8 -*-

module Md2htmlHelper
  class Content2HTML
    include ParserHelper

    def initialize(content, prefix = '')
      @content = content
      @prefix = prefix
    end

    def get_content
      @content
    end

    def get_format
      'markdown'
    end

    def id_prefix
      @prefix
    end
  end

  def md2html(content, app)
    return Content2HTML.new(content).to_html(app)
  end
end

# eof
