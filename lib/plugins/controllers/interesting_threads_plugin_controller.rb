# -*- coding: utf-8 -*-

class InterestingThreadsPluginController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  def mark_interesting
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_forum_url(current_forum)
      return :redirected
    end

    @thread, @id = get_thread

    CfInterestingThread.create!(thread_id: @thread.thread_id,
                                user_id: current_user.user_id)

    redirect_to cf_forum_url(current_forum),
      notice: t('plugins.interesting_threads.marked_interesting')
  end

  def mark_boring
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_forum_url(current_forum)
      return :redirected
    end

    @thread, @id = get_thread

    it = CfInterestingThread.where(thread_id: @thread.thread_id,
                                   user_id: current_user.user_id).first!

    it.destroy

    redirect_to cf_forum_url(current_forum),
      notice: t('plugins.interesting_threads.unmarked_interesting')
  end

  def list_threads
    @limit = conf('pagination', 50).to_i

    @threads = CfThread.
      preload(:forum, messages: [:owner, :tags, {close_vote: :voters}]).
      joins('INNER JOIN interesting_threads USING(thread_id)').
      where('interesting_threads.user_id = ?', current_user.user_id).
      order(:created_at).page(params[:p]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render @threads }
    end
  end
end


# eof
