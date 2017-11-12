module SortablesHelper
  def sort_query(valid_fields, query_object, replacements = {}, defaults = { dir: :asc })
    valid_fields = valid_fields.map(&:to_sym)
    controller_nam = controller_path.gsub(%r{/}, '-')

    cookie_key_scol = ('cforum_' + controller_nam + '-sort_column').to_sym
    cookie_key_sord = ('cforum_' + controller_nam + '-sort_direction').to_sym
    have_to_set_cookie = false

    if params[:sort].blank?
      @_sort_column = cookies[cookie_key_scol] || valid_fields.first
    else
      @_sort_column = params[:sort]
      have_to_set_cookie = true
    end

    if params[:dir].blank?
      @_sort_direction = cookies[cookie_key_sord] || defaults[:dir]
    else
      @_sort_direction = params[:dir]
      have_to_set_cookie = true
    end

    @_sort_direction = :asc unless %i[asc desc].include?(@_sort_direction.to_sym)
    @_sort_direction = @_sort_direction.to_sym
    @_sort_column = valid_fields.first unless valid_fields.include?(@_sort_column.to_sym)
    @_sort_column = @_sort_column.to_sym

    if have_to_set_cookie
      cookies[cookie_key_scol] = { value: @_sort_column, expires: 1.year.from_now }
      cookies[cookie_key_sord] = { value: @_sort_direction, expires: 1.year.from_now }
    end

    order_name = if replacements && replacements[@_sort_column]
                   replacements[@_sort_column]
                 else
                   '"' + @_sort_column.to_s + '"'
                 end

    query_object.order("(#{order_name}) #{@_sort_direction}")
  end

  def sortable(colname, col, method)
    if method.is_a?(Proc)
      link_asc = method.call(col, 'asc')
      link_desc = method.call(col, 'desc')
    else
      link_asc = send(method, sort: col, dir: 'asc')
      link_desc = send(method, sort: col, dir: 'desc')
    end

    html = if (sort_column == col) && (sort_direction == :desc)
             cf_link_to colname, link_asc, class: 'sortable sort-descending'
           elsif (sort_column == col) && (sort_direction == :asc)
             cf_link_to colname, link_desc, class: 'sortable sort-ascending'
           else
             cf_link_to colname, link_asc, class: 'sortable'
           end

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
