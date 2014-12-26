# -*- coding: utf-8 -*-

class InvisibleThreadsPluginController < ApplicationController
  authorize_controller { authorize_user }

  def list_threads
    @limit = conf('pagination', 50).to_i

    @threads = CfThread.
      preload(:forum, messages: [:owner, :tags, {close_vote: :voters}]).
      joins('INNER JOIN invisible_threads USING(thread_id)').
      where('invisible_threads.user_id = ?', current_user.user_id).
      order(:created_at).page(params[:p]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render @threads }
    end
  end

  def unhide_thread
    @thread = CfThread.find(params[:id])

    get_plugin_api(:mark_visible).call(@thread, current_user)

    redirect_to hidden_threads_url, notice: t('plugins.invisible_threads.thread_marked_visible')
  end
end


# eof
