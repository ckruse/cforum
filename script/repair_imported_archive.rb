#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

require 'strscan'

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('/dev/null')
ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.record_timestamps = false

current_block = 0
no_messages = 1000

def repair_content(content)
  ncnt = ''
  doc = StringScanner.new(content)

  while !doc.eos?
    if doc.scan(/\[\]\(\?t=t=(\d+)&m=m=(\d+)\)/)
      ncnt << "[?t=#{doc[1]}&m=#{doc[2]}](/?t=#{doc[1]}&m=#{doc[2]})"

    elsif doc.scan(/\[[^\]]+\\\]\(([^\)]+)\)[^\]]+\]/)
      str = doc.matched
      uri = doc[1]
      str.gsub!(/\(#{uri}\)/, '')
      str.gsub!(/\[/, '\[')
      str << "(#{uri})"

      ncnt << str[1..-1]

    elsif doc.scan(/\[(ref|link):/i)
      save = doc.pos
      directive = doc[1]
      content = ''
      no_end = true

      doc.skip(/\s/)

      while no_end and not doc.eos?
        content << doc.matched if doc.scan(/[^\]\\]/)

        if doc.scan(/\\\]/)
          content << '\]'
        elsif doc.scan(/\\/)
          content << "\\"
        elsif doc.scan(/\]/)
          no_end = false
        end
      end

      # empty directive
      if content.blank?
        ncnt << "[#{directive}:"
        doc.pos = save
        next
      end

      # unterminated directive
      if doc.eos? and no_end
        ncnt << "[#{directive}:"
        doc.pos = save
        next
      end

      title = href = nil

      if directive == 'ref'
        ref, href = content.split(';', 2)
        href, title = href.split('@title=', 2) if href =~ /@title=/

        if %w(self8 self81 self811 self812 sel811 sef811 slef812).include?(ref)
          href = "http://de.selfhtml.org/#{href}"
        elsif ref == 'self7'
          href = "http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href})"
        elsif ref == 'zitat'
          href = "http://community.de.selfhtml.org/zitatesammlung/zitat#{href})"
        else
          ncnt << "[#{directive}:"
          doc.pos = save
          next
        end

      elsif directive == 'link'
        href = content
        href, title = href.split('@title=', 2) if href =~ /@title=/
      end

      if href.blank?
        ncnt << "[#{directive}:"
        doc.pos = save
        next
      end

      ncnt << '[' + (title.blank? ? href : title) + "](#{href})"
    else
      ncnt << doc.matched if doc.scan(/./m)
    end
  end

  ncnt
end

begin
  msgs = Message.
         order(:message_id).
         limit(no_messages).
         offset(no_messages * current_block)

  current_block += 1

  msgs.each do |m|
    puts m.created_at.strftime('%Y-%m-%d') + ' - ' + m.mid.to_s

    m.content = repair_content(m.content)
    m.save
  end
end while not msgs.blank?


# eof
