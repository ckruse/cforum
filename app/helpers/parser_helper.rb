# -*- coding: utf-8 -*-

require Rails.root + 'lib/cf_kramdown.rb'
require Rails.root + 'lib/cforum_markup.rb'
require Rails.root + 'lib/cf_plaintext.rb'

module ParserHelper
  include CforumMarkup

  NOTIFY_MENTION = 'notify_mention'

  @@parser_modules = {}

  def self.parser_modules
    @@parser_modules
  end

  def get_content
    has_attribute?(:content) ? content.to_s : body.to_s
  end

  def get_format
    has_attribute?(:format) ? self.format : 'markdown'
  end

  def id_prefix
    'm' + (has_attribute?(:message_id) ? message_id.to_s : priv_message_id.to_s)
  end

  def get_mentions
    nil
  end

  def highlight_mentions(app, mentions, cnt)
    root_path = Rails.application.config.action_controller.relative_url_root || '/'
    mentions.each do |m|
      username = Regexp.escape(m[0])
      cnt = cnt.gsub(/(\A|[^a-zäöüß0-9_.@-])@(#{username})/) do
        classes = app.notification_center.notify(NOTIFY_MENTION, m)
        retval = $1 + '[@' + $2 + '](' + (root_path + 'users/' + m[1].to_s) + '){: .mention .registered-user'

        classes.each do |c|
          next if c.blank?
          retval << classes.join(" ")
        end

        retval + '}'
      end
    end

    cnt
  end

  def to_doc(app, opts = {})
    opts = opts.symbolize_keys!.reverse_merge!(
      input: 'CfMarkdown',
      coderay_wrap: nil,
      coderay_css: :class,
      coderay_line_numbers: nil,
      header_offset: opts[:header_start_index] || app.conf('header_start_index'),
      auto_id_prefix: id_prefix + '-',
      no_follow: true,
      root_url: opts[:root_url] || app.root_url,
      math_engine_opts: { preview: true },
      new_window: app.uconf('open_links_in_tab') == 'yes'
    )

    if @doc.blank?
      if Rails.env.development?
        load Rails.root + 'lib/cf_kramdown.rb'
        load Rails.root + 'lib/cforum_markup.rb'
      end

      cnt = get_content
      cnt = cforum2markdown(cnt) if get_format == 'cforum'

      mentions = get_mentions
      cnt = highlight_mentions(app, mentions, cnt) unless mentions.blank?

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

    @doc
  end

  def to_html(app, opts = {})
    to_doc(app, opts)

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

  def to_search(app, opts = {})
    doc = to_doc(app, opts)
    doc.to_plain
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
