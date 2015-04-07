# -*- coding: utf-8 -*-

module SortablesHelper
  def sort_query(valid_fields, query_object, replacements = {})
    valid_fields = valid_fields.map { |elem| elem.to_sym }
    @_sort_column = params[:sort] || valid_fields.first
    @_sort_direction =  params[:dir] || :asc

    @_sort_direction = :asc unless [:asc, :desc].include?(@_sort_direction.to_sym)
    @_sort_direction = @_sort_direction.to_sym
    @_sort_column = valid_fields.first unless valid_fields.include?(@_sort_column.to_sym)
    @_sort_column = @_sort_column.to_sym

    order_name = if replacements and replacements[@_sort_column]
                   replacements[@_sort_column]
                 else
                   @_sort_column
                 end

    return query_object.order("(#{order_name}) #{@_sort_direction}")
  end

  def sortable(colname, col, method)
    html = ERB::Util.h(colname) + ' ' # TODO use a better method to escape

    if method.is_a?(Proc)
      link_asc = method.call(col, 'asc')
      link_desc = method.call(col, 'desc')
    else
      link_asc = self.send(method, sort: col, dir: 'asc')
      link_desc = self.send(method, sort: col, dir: 'desc')
    end

    html << link_to('↓', link_asc)
    html << link_to('↑', link_desc)
    html.html_safe
  end

  def sort_column
    @_sort_column
  end

  def sort_direction
    @_sort_direction
  end

end

# eof
