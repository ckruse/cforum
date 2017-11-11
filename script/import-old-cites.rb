#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

ActiveRecord::Base.record_timestamps = false

def root_url
  'http://forum.selfhtml.org/'
end

include CForum::Tools

File.open(ARGV[0], 'r:utf-8') do |fd|
  xml_doc = Nokogiri::XML(fd)
  cites = xml_doc.xpath('/zitatesammlung/zitat')
  cites.each do |cite|
    c = Cite.new
    c.author = cite.xpath('./autor').first.content
    c.url = cite.xpath('./quelle').first.content
    c.cite = cite.xpath('./text').first.content
    c.created_at = c.updated_at = Date.parse(cite.xpath('./datum').first.content)
    c.old_id = cite.xpath('./id').first.content

    c.creator = cite.xpath('./vorschlaeger').first.content
    c.creator = nil if c.creator.blank?

    thread = message = nil

    if c.url.present? && c.url =~ /forum.de.selfhtml.org\/(?:my\/)?\?t=(\d+)&m=(\d+)/
      tid = Regexp.last_match(1)
      mid = Regexp.last_match(2)

    elsif c.url =~ /forum.de.selfhtml.org\/archiv\/\d+\/\d+\/t(\d+)\/#m(\d+)/
      tid = Regexp.last_match(1)
      mid = Regexp.last_match(2)

    elsif c.url =~ /forum.selfhtml.org\/\w+(\/\d{4,}\/[a-z]{3}\/\d{1,2}\/[^\/]+)\/(\d+)/
      slug = Regexp.last_match(1)
      mid = Regexp.last_match(2)

      thread = CfThread.preload(:forum).where(slug: slug).first

      if thread.present?
        message = Message.where(thread_id: thread.thread_id, message_id: mid).first
      end
    end

    if tid.present? && mid.present?
      thread = CfThread.preload(:forum).where(tid: tid.to_i).first

      if thread.present?
        message = Message.where(thread_id: thread.thread_id, mid: mid).first
        c.url = message_url(thread, message) if message.present?
      end
    end

    if message.present?
      c.message_id = message.message_id
      c.user_id = message.user_id
    end

    c.save!
  end
end

# eof
