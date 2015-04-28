# -*- coding: utf-8 -*-

require Rails.root + 'lib/cf_kramdown.rb'

module ParserHelper
  @@parser_modules = {}

  def self.parser_modules
    @@parser_modules
  end

  def get_content
    has_attribute?(:content) ? content.to_s : body.to_s
  end

  def id_prefix
    'm' + (has_attribute?(:message_id) ? message_id.to_s : priv_message_id.to_s)
  end

  def to_html(app, opts = {})
    opts = opts.symbolize_keys!.reverse_merge!(
      input: 'CfMarkdown',
      coderay_wrap: nil,
      coderay_css: :class,
      coderay_line_numbers: nil,
      header_offset: app.conf('header_start_index'),
      auto_id_prefix: id_prefix + '-',
      no_follow: true,
      root_url: app.root_url,
      smart_quotes: ["sbquo", "lsquo", "bdquo", "ldquo"]
    )

    if @doc.blank?
      if Rails.env.development?
        load Rails.root + 'lib/cf_kramdown.rb'
      end

      cnt = get_content
      ncnt = ''
      quote_level = 0

      cnt.lines.each do |l|
        current_ql = 0
        scanner = StringScanner.new(l)
        while scanner.scan(/^> /)
          current_ql += 1
        end

        if current_ql < quote_level and l !~ /^(?:> )*\s*$/m
          ncnt << ('> ' * current_ql) + "\n"
        elsif current_ql > quote_level
          ncnt << ('> ' * quote_level) + "\n"
        end
        quote_level = current_ql

        ncnt << l
      end

      @doc = Kramdown::Document.new(
        ncnt,
        opts
      )
    end

    html = @doc.to_cf_html

    # some users do things like this
    # > > > text
    # >
    # > > text
    # This produces a break in the block quote; to fix this we join
    # consecutive block quotes
    html.gsub!(/<\/blockquote>\s*<blockquote>/m, '')
    html.html_safe
  end

  def to_quote(app, opts = {})
    opts.symbolize_keys!.reverse_merge!(:quote_signature => app.uconf('quote_signature'))

    c = get_content

    if opts[:quote_signature] == 'no'
      sig_pos = c.rindex("\n-- \n")
      c = c[0..(sig_pos-1)] unless sig_pos.nil?
    end

    c = c.gsub(/\n/, "\n> ")
    c = '> ' + c unless c.blank?
    c
  end

  def to_txt
    get_content
  end

  module ClassMethods
    def to_internal(content)
      v = content.to_s
      v.gsub!(/\015\012|\015|\012/, "\012")

      v
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

end

# eof
