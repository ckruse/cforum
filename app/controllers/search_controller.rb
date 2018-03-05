require 'strscan'

class SearchController < ApplicationController
  before_action :set_start_stop

  include SearchHelper

  def set_start_stop
    @stop_date = if params[:stop_date].blank?
                   Time.zone.today
                 else
                   Time.zone.parse(params[:stop_date][:year].to_s + '-' +
                                   params[:stop_date][:month].to_s + '-' +
                                   params[:stop_date][:day].to_s + ' 23:59:59')
                 end

    @start_date = if params[:start_date].blank?
                    Time.zone.today - 2.years
                  else
                    begin
                      Time.zone.parse(params[:start_date][:year].to_s + '-' +
                                      params[:start_date][:month].to_s + '-' +
                                      params[:start_date][:day].to_s + ' 00:00:00')
                    rescue
                      Time.zone.today - 2.years
                    end
                  end

    doc = SearchDocument.order('document_created').first
    @min_year = doc.document_created.year if doc

    @order = params[:order]
    @order = 'rank' if @order.blank? || !%w[document_created rank].include?(@order)
  end

  def show
    @sections = SearchSection.order(:position, :name)
    @search_sections = params[:sections]

    unless current_user.try(:admin?)
      @sections = @sections.where('forum_id IS NULL OR forum_id IN (?)', @forums.map(&:forum_id))
    end

    @search_sections = if @search_sections.blank?
                         @sections.to_a.select(&:active_by_default).map(&:search_section_id)
                       else
                         @search_sections.map(&:to_i)
                       end

    if params[:term].present?
      @query = parse_search_terms(params[:term])
      @limit = conf('pagination_search').to_i

      @search_results, select, select_title = gen_search_query(@query)

      @search_results = @search_results
                          .select('*')
                          .select(select)
                          .where(search_section_id: @search_sections)
                          .where('document_created >= ?', @start_date)
                          .page(params[:page]).per(@limit)

      @search_results = @search_results
                          .where('document_created <= ?', @stop_date)

      # check for permissions
      unless current_user.try(:admin?)
        @search_results = @search_results.where('forum_id IS NULL OR forum_id IN (?)', @forums.map(&:forum_id))
      end

      order = if @order == 'document_created'
                'document_created DESC NULLS LAST, rank DESC'
              else
                'rank DESC, document_created DESC NULLS FIRST'
              end
      @search_results = @search_results.order(order)

      @search_results_w_title = if select_title.blank?
                                  @search_results.preload(:user, :search_section)
                                else
                                  SearchDocument
                                    .preload(:user, :search_section)
                                    .select('*, ' + select_title.join(', '))
                                    .from(@search_results)
                                    .order(order)
                                    .all
                                end
    end

    render :show
  end
end

# eof
