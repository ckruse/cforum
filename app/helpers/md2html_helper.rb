module Md2htmlHelper
  class Content2HTML
    include ParserHelper

    def initialize(content, prefix = '')
      @content = content
      @prefix = prefix
    end

    def md_content
      @content
    end

    def md_format
      'markdown'
    end

    def id_prefix
      @prefix
    end
  end

  def md2html(content, app)
    Content2HTML.new(content).to_html(app)
  end
end

# eof
