#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('/dev/null')
ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.record_timestamps = false

all_msgs = CfMessage.count();
current_block = 0
no_messages = 1000

while no_messages * current_block < all_msgs
  msgs = CfMessage.
         where("created_at > '2007-09-01 00:00'").
         order(:message_id).
         limit(no_messages).
         offset(no_messages * current_block)

  current_block += 1

  msgs.each do |m|
    puts m.created_at.strftime('%Y-%m-%d') + ' - ' + m.mid.to_s

    m.content = m.content.gsub(/\[\]\(\?t=t=(\d+)&m=m=(\d+)\)/) do |data|
      "[?t=#{$1}&m=#{$2}](/?t=#{$1}&m=#{$2})"
    end

    m.content = m.content.gsub(/\[ref:([^;\]]+);([^\]]+)@title=([^\]]+)\]/) do |data|
      ref = $1.downcase
      href = $2
      title = $3

      if %w(self8 self81 self811 self812 sel811 sef811 slef812).include?(ref)
        title = href if title.blank?
        "[#{title}](#{href})"
      elsif ref == 'self7'
        title = href if title.blank?
        "[#{title}](http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href})"
      elsif ref == 'zitat'
        title = href if title.blank?
        "[#{title}](http://community.de.selfhtml.org/zitatesammlung/zitat#{href})"
      else
        data
      end
    end

    m.content = m.content.gsub(/\[ref:([^;\]]+);([^\]]+)\]/) do |data|
      ref = $1.downcase
      href = $2

      if %w(self8 self81 self811 self812 sel811 sef811 slef812).include?(ref)
        "[#{href}](#{href})"
      elsif ref == 'self7'
        "[#{href}](http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href})"
      elsif ref == 'zitat'
        "[#{href}](http://community.de.selfhtml.org/zitatesammlung/zitat#{href})"
      else
        data
      end
    end


    m.save
  end
end


# eof
