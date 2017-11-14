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
      url: message_url(thread, message),
      relevance: base_relevance.to_f + (message.score.to_f / 10.0) + (message.accepted? ? 0.5 : 0.0) +
                 ('0.0' + message.created_at.year.to_s).to_f,
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

    SearchDocument.where('reference_id IN (?)', mids).delete_all if mids.present?
  end

  def rescore_message(message)
    message.reload

    doc = SearchDocument.where(reference_id: message.message_id).first
    return if doc.blank?

    base_relevance = conf('search_forum_relevance')

    doc.relevance = base_relevance.to_f +
                    (message.score.to_f / 10.0) +
                    (message.accepted? ? 0.5 : 0.0) +
                    ('0.0' + message.created_at.year.to_s).to_f
    doc.save
  end

  def search_index_cite(cite)
    return unless cite.archived?

    section = SearchSection.find_by(name: I18n.t('cites.cites'))
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

  def to_ts_query(terms)
    (terms.map do |t|
       negated = false
       wildcard = false
       term = t.gsub(/\\/, '\\\\\\')

       if t[0] == '-'
         negated = true
         term = term[1..-1]
       end

       if t[-1] == '*'
         wildcard = true
         term = term[0..-2]
       end

       if term.blank?
         nil
       else
         v = ''
         v << '!' if negated
         v << SearchDocument.connection.quote(term)
         v << ':*' if wildcard

         v
       end
     end).delete_if(&:blank?).join(' & ')
  end

  def ts_headline(content, query, name, dict = Cforum::Application.config.search_dict)
    title_config = 'MaxFragments=3'

    "ts_headline('" + dict + "', " + content +
      ", to_tsquery('" + dict + "', " + query + "), '" +
      title_config + "\') AS " + name
  end

  def parse_search_terms(search_str)
    doc = StringScanner.new(search_str)
    terms = {
      author: [],
      title: [],
      content: [],
      all: [],
      tags: []
    }

    current = :all

    until doc.eos?
      doc.skip(/\s+/)

      if doc.scan(/author:/)
        current = :author

      elsif doc.scan(/title:/)
        current = :title

      elsif doc.scan(/body:/)
        current = :content

      elsif doc.scan(/tag:/)
        current = :tags

      elsif doc.scan(/"/)
        term = ''
        until doc.eos?
          if doc.scan(/\\/)
            term << if doc.scan(/"/)
                      '"'
                    else
                      '\\'
                    end

          elsif doc.scan(/"/)
            break

          else
            doc.scan(/./)
            term << doc.matched
          end
        end

        terms[current] << term
        current = :all

      elsif doc.scan(/\S+/)
        terms[current] << doc.matched
        current = :all
      end
    end

    terms
  end

  def gen_search_query(query)
    search_results = SearchDocument
    select = ['relevance']
    select_title = []

    if query[:all].present?
      q = to_ts_query(query[:all])
      quoted_q = SearchDocument.connection.quote(q)

      search_results = search_results
                         .where("ts_document @@ to_tsquery('" +
                             Cforum::Application.config.search_dict +
                             "', ?)", q)
      select << "ts_rank_cd(ts_document, to_tsquery('" +
                Cforum::Application.config.search_dict +
                "', " + quoted_q + '), 32)'

      select_title << ts_headline("author || ' ' || title || ' ' || content", quoted_q, 'headline_doc')
    end

    if query[:title].present?
      q = to_ts_query(query[:title])
      quoted_q = SearchDocument.connection.quote(q)

      search_results = search_results
                         .where("ts_title @@ to_tsquery('" +
                             Cforum::Application.config.search_dict +
                             "', ?)", q)

      select << "ts_rank_cd(ts_title, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q +
                '), 32)'
      select_title << ts_headline('title', quoted_q, 'headline_title')
    end

    if query[:content].present?
      q = to_ts_query(query[:content])
      quoted_q = SearchDocument.connection.quote(q)

      search_results = search_results
                         .where("ts_content @@ to_tsquery('" +
                             Cforum::Application.config.search_dict +
                             "', ?)", q)

      select << "ts_rank_cd(ts_content, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q +
                '), 32)'
      select_title << ts_headline('content', quoted_q, 'headline_content')
    end

    if query[:author].present?
      q = to_ts_query(query[:author])
      quoted_q = SearchDocument.connection.quote(q)

      search_results = search_results
                         .where("ts_author @@ to_tsquery('simple', ?)", q)

      select << "ts_rank_cd(ts_author, to_tsquery('simple', " + quoted_q + '), 32)'
      select_title << ts_headline('author', quoted_q, 'headline_author', 'simple')
    end

    unless query[:tags].empty?
      search_results = search_results.where('tags @> ARRAY[?]::text[]', query[:tags].map(&:downcase))
    end

    [search_results, select.join(' + ') + ' AS rank', select_title]
  end
end

# eof
