#!/usr/bin/env ruby
dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')

include CForum::Tools
include ActionView::Helpers::TextHelper

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

$config_manager = ConfigManager.new # rubocop:disable Style/GlobalVars
section = SearchSection.find_by(name: I18n.t('cites.cites'))
no_messages = 1000
current_block = 0
start_date = nil
start_date = Time.zone.parse(ARGV[0]) unless ARGV.empty?

section = SearchSection.create!(name: I18n.t('cites.cites'), position: -1) if section.blank?
base_relevance = conf('search_cites_relevance')

loop do
  cites = Cite
            .includes(:user, :creator_user)
            .order(:cite_id)
            .limit(no_messages)
            .offset(no_messages * current_block)
            .where(archived: true)

  cites = cites.where('created_at >= ?', start_date) if start_date

  current_block += 1
  i = 0

  Message.transaction do
    cites.each do |cite|
      doc = SearchDocument.where(url: root_url + 'cites/' + cite.cite_id.to_s).first
      if doc.blank?
        doc = SearchDocument.new(url: root_url + 'cites/' + cite.cite_id.to_s)
      end

      doc.author = cite.author
      doc.user_id = cite.user_id
      doc.title = ''
      doc.content = cite.cite
      doc.search_section_id = section.search_section_id
      doc.relevance = base_relevance.to_f
      doc.lang = Cforum::Application.config.search_dict
      doc.document_created = cite.created_at
      doc.tags = []

      doc.save!

      i += 1
      puts cite.created_at.strftime('%Y-%m-%d') + ' - ' + cite.message_id.to_s if i == no_messages - 1
    end
  end

  break if cites.blank?
end

# eof
