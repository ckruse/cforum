#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')

include CForum::Tools
include ReferencesHelper

Rails.logger = Logger.new(Rails.root + 'log/message_references.log')
ActiveRecord::Base.logger = Rails.logger

public

def root_path
  Rails.application.config.action_controller.relative_url_root || '/'
end

def root_url
  (ActionMailer::Base.default_url_options[:protocol] || 'http') + '://' + ActionMailer::Base.default_url_options[:host] + root_path
end

def conf(name)
  $config_manager.get(name, nil, nil)
end

def uconf(name)
  conf(name)
end

def from_uri(uri)
  uri = uri.gsub(/#.*$/, '')
  return Regexp.last_match(1).to_i if uri =~ /\/(\d+)$/
  nil
end

$config_manager = ConfigManager.new
no_messages = 1000
current_block = 0
start_date = nil
start_date = Time.zone.parse(ARGV[0]) unless ARGV.empty?

begin
  msgs = Message
           .includes(:thread, :forum, :tags)
           .order(:message_id)
           .limit(no_messages)
           .offset(no_messages * current_block)
           .where(deleted: false)

  msgs = msgs.where('created_at >= ?', start_date) if start_date

  current_block += 1

  Message.transaction do
    msgs.each do |m|
      MessageReference.where(src_message_id: m.message_id).delete_all
      references = find_references(m.to_html(self), ['forum.de.selfhtml.org', 'forum.selfhtml.org'])

      next if references.blank?
      already_referenced = []

      references.each do |ref|
        mid = from_uri(ref)
        next if mid.blank?
        next if already_referenced.include?(mid)
        next unless Message.where(message_id: mid).exists?

        MessageReference.create!(src_message_id: m.message_id,
                                 dst_message_id: mid,
                                 created_at: DateTime.now,
                                 updated_at: DateTime.now)
        already_referenced << mid
      end
    end
  end
end while !msgs.blank?

# eof
