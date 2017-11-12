#!/usr/bin/env ruby
dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')
require File.join(dir, '..', 'lib', 'script_helpers.rb')

include CForum::Tools
include ReferencesHelper
include ScriptHelpers

Rails.logger = Logger.new(Rails.root + 'log/message_references.log')
ActiveRecord::Base.logger = Rails.logger

public

def from_uri(uri)
  uri = uri.gsub(/#.*$/, '')
  return Regexp.last_match(1).to_i if uri =~ %r{/(\d+)$} # rubocop:disable Performance/RegexpMatch
  nil
end

$config_manager = ConfigManager.new # rubocop:disable Style/GlobalVars
no_messages = 1000
current_block = 0
start_date = nil
start_date = Time.zone.parse(ARGV[0]) unless ARGV.empty?

loop do
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

  break if msgs.blank?
end

# eof
