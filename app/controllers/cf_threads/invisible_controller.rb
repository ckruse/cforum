# -*- coding: utf-8 -*-

class CfThreads::InvisibleController < ApplicationController
  authorize_controller { authorize_user }

  include SuspiciousHelper
  include HighlightHelper

  SHOW_INVISIBLE_THREADLIST = "show_invisible_threadlist"

  def list_invisible_threads
    @limit = conf('pagination').to_i

    order = uconf('sort_threads')
    case order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end


    @threads = CfThread.
               preload(:forum, messages: [:owner, :tags, {votes: :voters}]).
               includes(messages: :owner).
               joins('INNER JOIN invisible_threads iv ON iv.thread_id = threads.thread_id').
               where('iv.user_id = ?', current_user.user_id).
               where(deleted: false, messages: {deleted: false}).
               order(order).page(params[:page]).per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    check_threads_for_suspiciousness(@threads)
    check_threads_for_highlighting(@threads)

    ret = notification_center.notify(SHOW_INVISIBLE_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render @threads }
      end
    end
  end

  def unhide_thread
    @thread, @id = get_thread

    mark_visible(current_user, @thread)

    redirect_to cf_return_url(@thread),
                notice: t('plugins.invisible_threads.thread_marked_visible')
  end

  def hide_thread
    @thread, @id = get_thread

    mark_invisible(current_user, @thread)

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread),
                                notice: t('plugins.invisible_threads.thread_marked_invisible') }
      format.json { head :no_content }
    end
  end
end

# eof
