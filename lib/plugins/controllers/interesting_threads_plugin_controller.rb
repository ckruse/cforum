# -*- coding: utf-8 -*-

class InterestingThreadsPluginController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  SHOW_INTERESTING_THREADLIST = "show_interesting_threadlist"

  def mark_interesting
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return :redirected
    end

    @thread, @id = get_thread

    begin
      CfInterestingThread.create!(thread_id: @thread.thread_id,
                                  user_id: current_user.user_id)
    rescue ActiveRecord::RecordNotUnique
    end

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @thread.message),
                                notice: t('plugins.interesting_threads.marked_interesting') }
      format.json { render json: {status: :success, location: cf_thread_url(@thread) } }
    end
  end

  def mark_boring
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return :redirected
    end

    @thread, @id = get_thread

    it = CfInterestingThread.where(thread_id: @thread.thread_id,
                                   user_id: current_user.user_id).first!

    it.destroy

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @thread.message),
                                notice: t('plugins.interesting_threads.unmarked_interesting') }
      format.json { render json: {status: :success, location: cf_thread_url(@thread) } }
    end
  end

  def list_threads
    @limit = conf('pagination').to_i

    @threads = CfThread.
      preload(:forum, messages: [:owner, :tags, {votes: :voters}]).
      joins('INNER JOIN interesting_threads USING(thread_id)').
      where('interesting_threads.user_id = ?', current_user.user_id).
      order(:created_at).page(params[:p]).per(@limit)

    @threads.each do |thread|
      sort_thread(thread)
    end

    ret = notification_center.notify(SHOW_INTERESTING_THREADLIST, @threads)

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render @threads }
      end
    end
  end
end


# eof
