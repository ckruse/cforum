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

  def to_html(opts = {})
    opts = opts.symbolize_keys!.reverse_merge!(
      input: 'CfMarkdown',
      coderay_wrap: nil,
      coderay_css: :class,
      coderay_line_numbers: nil,
      header_offset: ApplicationController.instance.conf('header_start_index', 2),
      auto_id_prefix: 'msg-'
    )

    if @doc.blank?
      if Rails.env.development?
        load Rails.root + 'lib/cf_kramdown.rb'
      end

      @doc = Kramdown::Document.new(
        get_content,
        opts
      )
    end

    @doc.to_cf_html.html_safe
  end

  def to_quote(opts = {})
    opts.symbolize_keys!.reverse_merge!(:quote_signature => ApplicationController.instance.uconf('quote_signature', 'no'))

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

  # TODO: better method to load plugins, eval()ing them every time sucks
  # def read_syntax_plugins
  #   # read syntax plugins
  #   plugin_dir = Rails.root + 'lib/plugins/syntax'
  #   Dir.open(plugin_dir).each do |p|
  #     next unless File.file?(plugin_dir + p)
  #     load Rails.root + 'lib/plugins/syntax/' + p
  #   end
  # end


  module ClassMethods
    def to_internal(content)
      v = content.to_s
      v.gsub! /\015\012|\015|\012/, "\012"

      v
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

end

# eof
