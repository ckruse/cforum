# -*- encoding: utf-8 -*-

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

    unless current_forum.blank?
      @first_year = @first_year.where(forum_id: current_forum.forum_id)
      @last_year = @last_year.where(forum_id: current_forum.forum_id)
    end

    @first_year = @first_year.first.created_at.year
    @last_year = @last_year.first.created_at.year
  end

  def year
    tmzone = Time.zone.parse(params[:year] + '-12-31 00:00:00')
    first_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?", tmzone.utc_offset, params[:year]).
                  where(archived: true).
                  order('created_at ASC').
                  limit(1)
    last_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?", tmzone.utc_offset, params[:year]).
                 where(archived: true).
                 order('created_at DESC').
                 limit(1)

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

    if not first_month.blank? and not last_month.blank?
      first_month = first_month.first.created_at
      last_month = last_month.first.created_at

      q = ""
      q << "forum_id = #{current_forum.forum_id} AND " unless current_forum.blank?
      q << 'deleted = false AND ' unless @view_all
      mon = first_month
      loop do
        if CfThread.exists?(["#{q}DATE_TRUNC('month', created_at) = DATE_TRUNC('month', ?::timestamp without time zone)", mon])
          @months << mon.to_date
        end

        break if mon.month == last_month.month
        mon = Time.zone.parse(mon.year.to_s + "-" + (mon.month + 1).to_s + "-" + mon.day.to_s + " 00:00:00")
      end
    end
  end

  def month
    months = [nil, 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
    month_num = months.index(params[:month])

    raise ActiveRecord::RecordNotFound if month_num.nil?

    @page  = params[:page].to_i
    @limit = uconf('pagination').to_i

    @page  = 0 if @page < 0
    @limit = 50 if @limit <= 0

    order = uconf('sort_threads')
    case order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end


    @month = Date.civil(params[:year].to_i, month_num, 1)

    _, @threads = get_threads(current_forum, order, current_user, false, archived: true)
    @threads = @threads.
               where("DATE_TRUNC('month', threads.created_at) = ?",
                     params[:year] + '-' + sprintf("%02d", month_num.to_i) + '-01 00:00').
               page(@page).
               per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    ret = []
    ret << check_threads_for_suspiciousness(@threads)
    ret << check_threads_for_highlighting(@threads)
    ret << mark_threads_interesting(@threads)
    ret << leave_out_invisible_for_threadlist(@threads)
    ret << is_read_threadlist(@threads)
    ret << open_close_threadlist(@threads)
    ret << thread_list_link_tags

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render json: @threads, include: {messages: {include: [:owner, :tags]} } }
      end
    end
  end
end

# eof
