# -*- encoding: utf-8 -*-

class CfArchiveController < ApplicationController
  authorize_action([:years]) { authorize_forum(permission: :read?) }

  include TagsHelper
  include ThreadsHelper

  SHOW_ARCHIVE_THREADLIST  = "show_archive_threadlist"

  def years
    @first_year = CfThread.order('created_at ASC').limit(1).first.created_at.year
    @last_year = CfThread.order('created_at DESC').limit(1).first.created_at.year
  end

  def year
    tmzone = Time.zone.parse(params[:year] + '-12-31 00:00:00')
    first_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?", tmzone.utc_offset, params[:year]).
                  order('created_at ASC').
                  limit(1).first.created_at
    last_month = CfThread.where("EXTRACT(year FROM created_at + INTERVAL '? seconds') = ?", tmzone.utc_offset, params[:year]).
                 order('created_at DESC').
                 limit(1).first.created_at

    @months = []
    mon = first_month
    loop do
      @months << mon.to_date

      break if mon.month == last_month.month
      mon = Date.civil(mon.year, mon.month + 1, mon.day)
    end
  end

  def month
    months = [nil, 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
    month_num = months.index(params[:month])

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

    @threads = get_threads(current_forum, order, current_user, archived: true)
    @threads = @threads.
               where("DATE_TRUNC('month', threads.created_at) = ?",
                     params[:year] + '-' + sprintf("%02d", month_num.to_i) + '-01 00:00').
               page(@page).
               per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    ret = notification_center.notify(SHOW_ARCHIVE_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render json: @threads, include: {messages: {include: [:owner, :tags]} } }
      end
    end
  end
end

# eof
