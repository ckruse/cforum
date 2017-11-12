class CfThreads::InvisibleController < ApplicationController
  authorize_controller { authorize_user }

  include SuspiciousHelper
  include HighlightHelper
  include InterestingHelper
  include LinkTagsHelper
  include OpenCloseHelper

  def list_invisible_threads
    @limit = conf('pagination').to_i

    order = uconf('sort_threads')
    order = case order
            when 'ascending'
              'threads.created_at ASC'
            when 'newest-first'
              'threads.latest_message DESC'
            else
              'threads.created_at DESC'
            end

    cache = get_cached_entry(:invisible, current_user.user_id) || {}

    @threads = CfThread
                 .preload(:forum, messages: [:owner, :tags, { votes: :voters }])
                 .includes(messages: :owner)
                 .joins('INNER JOIN invisible_threads iv ON iv.thread_id = threads.thread_id')
                 .where('iv.user_id = ?', current_user.user_id)
                 .where(deleted: false, messages: { deleted: false })
                 .order(order).page(params[:page]).per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
      cache[thread.thread_id] = true
    end

    set_cached_entry(:invisible, current_user.user_id, cache)

    ret = []
    ret << check_threads_for_suspiciousness(@threads)
    ret << check_threads_for_highlighting(@threads)
    ret << mark_threads_interesting(@threads)
    ret << read_threadlist?(@threads)
    ret << open_close_threadlist(@threads)
    ret << thread_list_link_tags

    return if ret.include?(:redirected)

    respond_to do |format|
      format.html
      format.json { render @threads }
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
      format.html do
        redirect_to cf_return_url(@thread),
                    notice: t('plugins.invisible_threads.thread_marked_invisible')
      end
      format.json { head :no_content }
    end
  end
end

# eof
