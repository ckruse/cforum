#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('/dev/null')
ActiveRecord::Base.logger = Rails.logger

all_msgs = CfMessage.count();
current_block = 0
no_messages = 1000

while no_messages * current_block < all_msgs
  msgs = CfMessage.
         order(:message_id).
         limit(no_messages).
         offset(no_messages * current_block)

  current_block += 1

  msgs.each do |m|
    puts m.created_at.strftime('%Y-%m-%d') + ' - ' + m.mid.to_s

    m.content = m.content.gsub(/\[\]\(\?t=t=(\d+)&m=m=(\d+)\)/) do |data|
      "[?t=#{$1}&m=#{$2}](/?t=#{$1}&m=#{$2})"
    end

    m.content = m.content.gsub(/\[ref:([^;]+);([^\]]+)@title=([^\]]+)\]/) do |data|
      if $1 == 'self812'
        "[#{$3}](#{$2})"
      else
        raise "unknown ref: [ref:$1;$2@title=$3]"
      end
    end

    m.content = m.content.gsub(/\[ref:([^;]+);([^\]]+)\]/) do |data|
      if $1 == 'self812'
        "[#{$2}](#{$2})"
      else
        raise "unknown ref: [ref:$1;$2]"
      end
    end


    m.save
  end
end


# eof
