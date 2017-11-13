#!/usr/bin/env ruby
dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')

include CForum::Tools

Rails.logger = Logger.new(Rails.root + 'log/reindex.log')
ActiveRecord::Base.logger = Rails.logger

public

def root_path
  Rails.application.config.action_controller.relative_url_root || '/'
end

def root_url
  (ActionMailer::Base.default_url_options[:protocol] || 'http') + '://' +
    ActionMailer::Base.default_url_options[:host] + root_path
end

def conf(name)
  $config_manager.get(name, nil, nil) # rubocop:disable Style/GlobalVars
end

def uconf(name)
  conf(name)
end

$config_manager = ConfigManager.new # rubocop:disable Style/GlobalVars
sections = {}
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
  i = 0

  Message.transaction do
    msgs.each do |m|
      base_relevance = conf('search_forum_relevance')

      doc = SearchDocument.where(reference_id: m.message_id).first
      doc = SearchDocument.new(reference_id: m.message_id) if doc.blank?

      if sections[m.forum_id].blank?
        sections[m.forum_id] = SearchSection.where(forum_id: m.forum_id).first
        if sections[m.forum_id].blank?
          sections[m.forum_id] = SearchSection.create!(name: m.forum.name,
                                                       position: -1,
                                                       forum_id: m.forum_id)
        end
      end

      doc.author = m.author
      doc.user_id = m.user_id
      doc.title = m.subject
      doc.content = m.to_search(self, notify_mentions: false)
      doc.search_section_id = sections[m.forum_id].search_section_id
      doc.url = message_url(m.thread, m)
      doc.relevance = base_relevance.to_f + (m.score.to_f / 10.0) + (m.accepted? ? 0.5 : 0.0) +
                      ('0.0' + m.created_at.year.to_s).to_f
      doc.lang = Cforum::Application.config.search_dict
      doc.document_created = m.created_at
      doc.tags = m.tags.map { |t| t.tag_name.downcase }
      doc.forum_id = m.forum_id

      doc.save!

      i += 1
      puts m.created_at.strftime('%Y-%m-%d') + ' - ' + m.message_id.to_s if i == no_messages - 1
    end
  end

  break if msgs.blank?
end

# eof
