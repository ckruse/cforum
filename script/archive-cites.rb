#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config', 'boot')
require File.join(dir, '..', 'config', 'environment')
require File.join(dir, '..', 'lib', 'tools.rb')
require File.join(dir, '..', 'lib', 'script_helpers.rb')

include CForum::Tools
include ReferencesHelper
include ScriptHelpers
include AuditHelper

$config_manager = ConfigManager.new

def search_index(cite)
  section = SearchSection.find_by_name(I18n.t('cites.cites'))
  section = SearchSection.create!(name: I18n.t('cites.cites'), position: -1) if section.blank?
  base_relevance = conf('search_cites_relevance')

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
end

min_age = conf('cites_min_age_to_archive', nil).to_i
cites = Cite
          .preload(:votes)
          .where('archived = false AND NOW() >= created_at + INTERVAL ?', min_age.to_s + ' weeks')
          .all

Rails.logger.info "Running cite archiver for #{cites.length} cites"

cites.each do |cite|
  if cite.score > 0
    Rails.logger.info "Archiving cite #{cite.cite_id}"
    cite.archived = true
    cite.save
    search_index(cite)
    audit(cite, 'archive', nil)

  else
    cite.destroy
    audit(cite, 'destroy', nil)
  end
end
