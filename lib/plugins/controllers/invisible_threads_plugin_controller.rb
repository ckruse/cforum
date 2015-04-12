# -*- coding: utf-8 -*-

class InvisibleThreadsPluginController < ApplicationController
  authorize_controller { authorize_user }

  SHOW_INVISIBLE_THREADLIST = "show_invisible_threadlist"

  def list_threads
    @limit = conf('pagination').to_i

    @threads = CfThread.
      preload(:forum, messages: [:owner, :tags, {votes: :voters}]).
      joins('INNER JOIN invisible_threads USING(thread_id)').
      where('invisible_threads.user_id = ?', current_user.user_id).
      order(:created_at).page(params[:p]).per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    ret = notification_center.notify(SHOW_INVISIBLE_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render @threads }
      end
    end
  end

  def unhide_thread
    @thread = CfThread.find(params[:id])

    get_plugin_api(:mark_visible).call(@thread, current_user)

    redirect_to cf_return_url(@thread),
                notice: t('plugins.invisible_threads.thread_marked_visible')
  end
end


# eof
