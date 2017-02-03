# -*- coding: utf-8 -*-

require 'strscan'

class SearchController < ApplicationController
  before_action :set_start_stop

  include SearchHelper

  def set_start_stop
    unless params[:stop_date].blank?
      @stop_date = Time.zone.parse(params[:stop_date][:year].to_s + '-' +
                                   params[:stop_date][:month].to_s + '-' +
                                   params[:stop_date][:day].to_s + ' 23:59:59')
    else
      @stop_date = Date.today
    end

    unless params[:start_date].blank?
      @start_date = Time.zone.parse(params[:start_date][:year].to_s + '-' +
                                    params[:start_date][:month].to_s + '-' +
                                    params[:start_date][:day].to_s + ' 00:00:00')
    else
      @start_date = Date.today - 2.years
    end

    doc = SearchDocument.order('document_created').first
    @min_year = doc.document_created.year if doc

    @order = params[:order]
    @order = 'rank' if @order.blank? or not %w(document_created rank).include?(@order)
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
      @query = parse_search_terms(params[:term])
      @limit = conf('pagination_search').to_i

      @search_results, select, select_title = gen_search_query(@query)

      @search_results = @search_results.
                        select("*").
                        select(select).
                        where(search_section_id: @search_sections).
                        where('document_created >= ?', @start_date).
                        page(params[:page]).per(@limit)

      @search_results = @search_results.
                        where('document_created <= ?', @stop_date)

      # check for permissions
      unless current_user.try(:admin?)
        @search_results = @search_results.where('forum_id IS NULL OR forum_id IN (?)', @forums.map { |f| f.forum_id })
      end

      order = if @order == 'document_created'
                'document_created DESC NULLS LAST, rank DESC'
              else
                'rank DESC, document_created DESC NULLS FIRST'
              end
      @search_results = @search_results.order(order)

      unless select_title.blank?
        @search_results_w_title = SearchDocument.
                                  preload(:user, :search_section).
                                  select('*, ' + select_title.join(", ")).
                                  from(@search_results).
                                  order(order).
                                  all
      else
        @search_results_w_title = @search_results.preload(:user, :search_section)
      end
    end

    render :show
  end

end

# eof
