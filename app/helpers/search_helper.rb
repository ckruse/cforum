# -*- coding: utf-8 -*-

module SearchHelper
  def search_index_message(thread, message)
    section = SearchSection.where(forum_id: message.forum_id).first
    if section.blank?
      section = SearchSection.create!(name: message.forum.name,
                                      position: -1,
                                      forum_id: message.forum_id)
    end

    base_relevance = conf('search_forum_relevance')


    opts = {
      reference_id: message.message_id,
      forum_id: message.forum_id,
      search_section_id: section.search_section_id,
      author: message.author,
      user_id: message.user_id,
      title: message.subject,
      content: message.to_search(self),
      url: message_url(message.thread, message),
      relevance: base_relevance.to_f + (message.score.to_f / 10.0) + (message.flags['accepted'] == 'yes' ? 0.5 : 0.0) + ('0.0' + message.created_at.year.to_s).to_f,
      lang: Cforum::Application.config.search_dict,
      document_created: message.created_at,
      tags: message.tags.map { |t| t.tag_name.downcase }
    }

    doc = SearchDocument.where(reference_id: message.message_id).first
    doc = SearchDocument.new if doc.blank?

    doc.attributes = opts
    doc.save!
  end

  def search_unindex_message_with_answers(message)
    mids = [message.message_id]
    message.all_answers do |m|
      mids << m.message_id
    end

    SearchDocument.delete_all(['reference_id IN (?)', mids]) unless mids.blank?
  end

  def rescore_message(message)
    message.reload

    doc = SearchDocument.where(reference_id: message.message_id).first
    return if doc.blank?

    base_relevance = conf('search_forum_relevance')

    doc.relevance = base_relevance.to_f +
                    (message.score.to_f / 10.0) +
                    (message.flags['accepted'] == 'yes' ? 0.5 : 0.0) +
                    ('0.0' + message.created_at.year.to_s).to_f
    doc.save
  end

  def search_index_cite(cite)
    return unless cite.archived?

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
end

# eof
