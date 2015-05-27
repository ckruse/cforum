# -*- coding: utf-8 -*-

require 'strscan'

class CfSearchController < ApplicationController
  def to_ts_query(terms)
    (terms.map { |t|
       if t[0] == '-'
         '!' + SearchDocument.connection.quote(t[1..-1])
       else
         SearchDocument.connection.quote(t)
       end
     }).join(" & ")
  end

  def show
    @sections = SearchSection.order(:position, :name)
    @search_sections = params[:sections]

    unless current_user.try(:admin?)
      @sections = @sections.where('forum_id IS NULL OR forum_id IN (?)', @forums.map { |f| f.forum_id })
    end

    if @search_sections.blank?
      @search_sections = (@sections.to_a.select { |s| s.active_by_default }).map { |s| s.search_section_id }
    else
      @search_sections = @search_sections.map { |s| s.to_i }
    end

    unless params[:term].blank?
      @query = parse_terms(params[:term])
      @limit = conf('pagination_search').to_i

      @search_results = SearchDocument.select("*")
      select = ['relevance']
      select_title = []

      unless @query[:all].blank?
        q = to_ts_query(@query[:all])
        quoted_q = SearchDocument.connection.quote(q)

        @search_results = @search_results.
                          where("ts_document @@ to_tsquery('" +
                                Cforum::Application.config.search_dict +
                                "', ?)", q)
        select << "ts_rank_cd(ts_document, to_tsquery('" +
          Cforum::Application.config.search_dict +
          "', " + quoted_q + "), 32)"

        select_title << "ts_headline('" +
          Cforum::Application.config.search_dict +
          "', author || ' ' || title || ' ' || content, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q + ")) AS headline_doc"
      end

      unless @query[:title].blank?
        q = to_ts_query(@query[:title])
        quoted_q = SearchDocument.connection.quote(q)

        @search_results = @search_results.
                          where("ts_title @@ to_tsquery('" +
                                Cforum::Application.config.search_dict +
                                "', ?)", q)

        select << "ts_rank_cd(ts_title, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q + "), 32)"
        select_title << "ts_headline('" +
          Cforum::Application.config.search_dict +
          "', title, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q + ")) AS headline_title"
      end

      unless @query[:content].blank?
        q = to_ts_query(@query[:content])
        quoted_q = SearchDocument.connection.quote(q)

        @search_results = @search_results.
                          where("ts_content @@ to_tsquery('" +
                                Cforum::Application.config.search_dict +
                                "', ?)", q)

        select << "ts_rank_cd(ts_content, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q + "), 32)"
        select_title << "ts_headline('" +
          Cforum::Application.config.search_dict +
          "', content, to_tsquery('" + Cforum::Application.config.search_dict + "', " + quoted_q + ")) AS headline_content"
      end

      unless @query[:author].blank?
        q = to_ts_query(@query[:author])
        quoted_q = SearchDocument.connection.quote(q)

        @search_results = @search_results.
                          where("ts_author @@ to_tsquery('simple', ?)", q)

        select << "ts_rank_cd(ts_author, to_tsquery('simple', " + quoted_q + "), 32)"
        select_title << "ts_headline('" +
          Cforum::Application.config.search_dict +
          "', author, to_tsquery('simple', " + quoted_q + ")) AS headline_author"
      end

      unless @query[:tags].empty?
        @search_results = @search_results.where("tags @> ARRAY[?]::text[]", @query[:tags].map { |t| t.downcase })
      end


      @search_results = @search_results.
                        preload(:user, :search_section).
                        select(select.join(' + ') + " AS rank").
                        where(search_section_id: @search_sections).
                        order('rank DESC, document_created DESC').
                        page(params[:page]).per(@limit)
      @search_results = @search_results.select(select_title.join(', ')) unless select_title.blank?

      unless params[:start_date].blank?
        @search_results = @search_results.
                          where('document_created >= ?',
                                Time.zone.parse(params[:start_date][:year].to_s + '-' +
                                                params[:start_date][:month].to_s + '-' +
                                                params[:start_date][:day].to_s + ' 00:00:00'))
      end

      unless params[:stop_date].blank?
        @search_results = @search_results.
                          where('document_created <= ?',
                                Time.zone.parse(params[:stop_date][:year].to_s + '-' +
                                                params[:stop_date][:month].to_s + '-' +
                                                params[:stop_date][:day].to_s + ' 23:59:59'))
      end

      # check for permissions
      unless current_user.try(:admin?)
        @search_results = @search_results.where('forum_id IS NULL OR forum_id IN (?)', @forums.map { |f| f.forum_id })
      end

    end

    render :show
  end

  def parse_terms(search_str)
    doc = StringScanner.new(search_str)
    terms = {
      author: [],
      title: [],
      content: [],
      all: [],
      tags: []
    }

    current = :all

    while !doc.eos?
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
        while !doc.eos?
          if doc.scan(/\\/)
            if doc.scan(/"/)
              term << '"'
            else
              term << '\\'
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
end

# eof
