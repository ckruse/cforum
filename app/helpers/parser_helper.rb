# rubocop:disable Style/ClassVars

require Rails.root + 'lib/cf_kramdown.rb'
require Rails.root + 'lib/cforum_markup.rb'
require Rails.root + 'lib/cf_plaintext.rb'

module ParserHelper
  include CforumMarkup
  include HighlightHelper

  @@parser_modules = {}

  def self.parser_modules
    @@parser_modules
  end

  def md_content
    has_attribute?(:content) ? content.to_s : body.to_s
  end

  def md_format
    has_attribute?(:format) ? format : 'markdown'
  end

  def id_prefix
    'm' + (has_attribute?(:message_id) ? message_id.to_s : priv_message_id.to_s)
  end

  def md_mentions
    nil
  end

  def get_created_at # rubocop:disable Naming/AccessorMethodName
    Time.zone.now
  end

  def highlight_mentions(app, mentions, cnt, do_notify)
    root_path = Rails.application.config.action_controller.relative_url_root || '/'
    already_replaced = {}

    mentions.each do |m|
      next if already_replaced[m[0]]
      already_replaced[m[0]] = true
      username = Regexp.escape(m[0])

      cnt = cnt.gsub(/(\A|[^a-zäöüß0-9_.@\\-])@(#{username})\b/) do
        classes = []
        classes << highlight_notify_mention(m, app) if do_notify

        retval = Regexp.last_match(1) + '[@' + Regexp.last_match(2) +
                 '](' + (root_path + 'users/' + m[1].to_s) + '){: .mention .registered-user'

        if classes.present?
          classes.each do |c|
            next if c.blank?
            retval << classes.join(' ')
          end
        end

        retval + '}'
      end
    end

    cnt
  end

  def to_doc(app, opts = {})
    opts = opts.symbolize_keys!.reverse_merge!(
      input: 'CfMarkdown',
      header_offset: opts[:header_start_index] || app.conf('header_start_index'),
      auto_id_prefix: id_prefix + '-',
      no_follow: true,
      root_url: opts[:root_url] || app.root_url,
      math_engine_opts: { preview: true },
      notify_mentions: true,
      syntax_highlighter: 'rouge',
      with_styles: get_created_at < Time.zone.parse('2017-03-10 15:00')
    )

    if @doc.blank?
      if Rails.env.development?
        load Rails.root + 'lib/cf_kramdown.rb'
        load Rails.root + 'lib/cforum_markup.rb'
      end

      cnt = md_content
      cnt = cforum2markdown(cnt) if md_format == 'cforum'

      mentions = md_mentions
      cnt = highlight_mentions(app, mentions, cnt, opts[:notify_mentions]) if mentions.present?

      cnt.gsub!(/\\@/, '@')

      ncnt = ''
      quote_level = 0

      cnt.lines.each do |l|
        current_ql = 0
        scanner = StringScanner.new(l)
        current_ql += 1 while scanner.scan(/^> ?/)

        if current_ql < quote_level && l !~ /^(?:> ?)*\s*$/m
          ncnt << ('> ' * current_ql) + "\n"
        elsif current_ql > quote_level
          ncnt << ('> ' * quote_level) + "\n"
        end
        quote_level = current_ql

        if l =~ /^(?:> )*~~~\s*(?:\w+)/
          l = l.gsub(/~~~(\s*)(\w+)/) do
            '~~~' + Regexp.last_match(1) + Regexp.last_match(2).downcase
          end
        end

        ncnt << l
      end

      opts[:app] = app
      @doc = Kramdown::Document.new(
        ncnt,
        opts
      )
    end

    @doc
  end

  def to_html(app, opts = {})
    to_doc(app, opts)

    html = span_emojis(@doc.to_cf_html)

    # some users do things like this
    # > > > text
    # >
    # > > text
    # This produces a break in the block quote; to fix this we join
    # consecutive block quotes
    html.gsub!(%r{</blockquote>\s*<blockquote>}m, '')
    html.html_safe
  end

  def span_emojis(html)
    if @_emojis.blank?
      @_emojis = JSON.parse(File.read(Rails.root + 'config/emojis.json'))
      @_reversed_emojis = @_emojis.invert
      rx_values = @_emojis.values.map { |emoji| Regexp.quote emoji }
      @_emojis_regex = /#{rx_values.join('|')}/
    end

    html.gsub(@_emojis_regex) do |emoji|
      %(<span role="img" aria-label="#{@_reversed_emojis[emoji].tr('_', ' ')}" class="emoji">#{emoji}</span>)
    end
  end

  def to_quote(app, opts = {})
    opts.symbolize_keys!.reverse_merge!(quote_signature: app.uconf('quote_signature'))

    c = md_content

    if opts[:quote_signature] == 'no'
      sig_pos = c.rindex("\n-- \n")
      c = c[0..(sig_pos - 1)] unless sig_pos.nil?
    end

    c = c.gsub(/\n/, "\n> ")
    c = '> ' + c if c.present?
    c
  end

  def to_search(app, opts = {})
    doc = to_doc(app, opts)
    doc.to_plain
  end

  def to_txt
    md_content
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
