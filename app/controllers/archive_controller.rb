class ArchiveController < ApplicationController
  authorize_action([:years]) { authorize_forum(permission: :read?) }

  include TagsHelper
  include ThreadsHelper
  include SuspiciousHelper
  include HighlightHelper
  include InterestingHelper
  include LinkTagsHelper
  include OpenCloseHelper

  def years
    @first_year = CfThread.order('created_at ASC').limit(1)
    @last_year = CfThread.order('created_at DESC').limit(1)

    if current_forum.present?
      @first_year = @first_year.where(forum_id: current_forum.forum_id)
      @last_year = @last_year.where(forum_id: current_forum.forum_id)
    end

    @first_year = @first_year.first.created_at.year
    @last_year = @last_year.first.created_at.year
  end

  def year
    tmzone = Time.zone.parse(params[:year] + '-12-31 00:00:00')
    first_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?",
                                 tmzone.utc_offset, params[:year])
                    .where(archived: true)
                    .order('created_at ASC')
                    .limit(1)
    last_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?",
                                tmzone.utc_offset, params[:year])
                   .where(archived: true)
                   .order('created_at DESC')
                   .limit(1)

    if current_forum
      first_month = first_month.where(forum_id: current_forum.forum_id)
      last_month = last_month.where(forum_id: current_forum.forum_id)
    end

    unless @view_all
      first_month = first_month.where('threads.deleted = false')
      last_month = last_month.where('threads.deleted = false')
    end

    @months = []
    @year = tmzone

    return if first_month.blank? || last_month.blank?

    first_month = first_month.first.created_at
    last_month = last_month.first.created_at

    q = ''
    q << "forum_id = #{current_forum.forum_id} AND " if current_forum.present?
    q << 'deleted = false AND ' unless @view_all
    mon = first_month
    loop do
      if CfThread.exists?(["#{q}DATE_TRUNC('month', created_at) = DATE_TRUNC('month', ?::timestamp without time zone)",
                           mon])
        @months << mon.to_date
      end

      break if mon.month == last_month.month
      mon = Time.zone.parse(mon.year.to_s + '-' + (mon.month + 1).to_s + '-' + mon.day.to_s + ' 00:00:00')
    end
  end

  def month
    months = [nil, 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
    month_num = months.index(params[:month])

    raise ActiveRecord::RecordNotFound if month_num.nil?

    @page  = params[:page].to_i
    @limit = uconf('pagination').to_i

    @page  = 0 if @page.negative?
    @limit = 50 if @limit <= 0

    order = uconf('sort_threads')
    order = case order
            when 'ascending'
              'threads.created_at ASC'
            when 'newest-first'
              'threads.latest_message DESC'
            else
              'threads.created_at DESC'
            end

    @month = Time.zone.parse(params[:year].to_i.to_s + '-' + month_num.to_s + '-01 00:00')
    last_day_of_month = @month.end_of_month

    _, @threads = get_threads(current_forum, order, current_user, false, archived: true)
    @threads = @threads
                 .where('threads.created_at BETWEEN ? AND ?', @month, last_day_of_month)
                 .page(@page)
                 .per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    ret = []
    ret << check_threads_for_suspiciousness(@threads)
    ret << check_threads_for_highlighting(@threads)
    ret << mark_threads_interesting(@threads)
    ret << leave_out_invisible_for_threadlist(@threads)
    ret << read_threadlist?(@threads)
    ret << open_close_threadlist(@threads)
    ret << thread_list_link_tags

    return if ret.include?(:redirected)

    respond_to do |format|
      format.html
      format.json { render json: @threads, include: { messages: { include: %i[owner tags] } } }
    end
  end
end

# eof
