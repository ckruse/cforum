# -*- coding: utf-8 -*-

class InvisibleThreadsPlugin < Plugin
  def initialize(*args)
    super(*args)

    @cache = {}

    register_plugin_api :mark_invisible do |thread, user|
      mark_invisible(thread, user)
    end
    register_plugin_api :mark_visible do |thread, user|
      mark_visible(thread, user)
    end
    register_plugin_api :is_invisible do |thread, user|
      is_invisible(thread, user)
    end
  end

  def is_invisible(thread, user)
    return if user.blank?

    thread = [thread] if not thread.is_a?(Array) and not thread.is_a?(ActiveRecord::Relation)
    thread = thread.map {|t| t.is_a?(CfThread) ? t.thread_id : t.to_i}

    user_id = user.is_a?(CfUser) ? user.user_id : user

    new_cache = {}

    if @cache[user_id]
      has_all = true
      retval = []

      thread.each do |t|
        if not @cache[user_id].has_key?(t)
          has_all = false
        else
          retval << t if @cache[user_id][t]
        end
        new_cache[t] = false
      end

      return retval if has_all
    else
      thread.each do |t|
        new_cache[t] = false
      end
    end

    invisible_threads = []

    result = CfThread.connection.execute("SELECT thread_id FROM invisible_threads WHERE thread_id IN (" + thread.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      t = row['thread_id'].to_i
      invisible_threads << t
    end

    @cache[user_id] ||= {}
    @cache[user_id] = @cache[user_id].merge(new_cache)

    invisible_threads
  end

  def mark_invisible(thread, user)
    return if user.blank?
    thread = [thread] unless thread.is_a?(Array)

    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }
    user_id = user.is_a?(CfUser) ? user.user_id : user

    sql = "INSERT INTO invisible_threads (user_id, thread_id) VALUES (" + user_id.to_s + ", "

    thread.each do |t|
      begin
        CfMessage.connection.execute(sql + t.to_s + ")")
      rescue ActiveRecord::RecordNotUnique
      end
    end

    thread
  end

  def mark_visible(thread, user)
    return if user.blank?
    thread = [thread] unless thread.is_a?(Array)

    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }
    user_id = user.is_a?(CfUser) ? user.user_id : user

    sql = "DELETE FROM invisible_threads WHERE user_id = " +
          user_id.to_s + " AND thread_id = "

    CfThread.transaction do
      thread.each do |t|
        CfMessage.connection.execute(sql + t.to_s)
      end
    end
  end

  def modify_threadlist_query_obj()
    return unless current_user

    @modified = true

    return Proc.new { |threads|
      threads.where("NOT EXISTS(SELECT thread_id FROM invisible_threads WHERE user_id = ? AND invisible_threads.thread_id = threads.thread_id)", current_user.user_id)
    }
  end

  def show_threadlist(threads)
    return unless current_user

    # when we modified the query object we know that there can't be
    # any invisible threads; so avoid the extra work and just mark
    # them all as visible in the cache
    if @modified
      @cache[current_user.user_id] ||= {}
      threads.each do |t|
        @cache[current_user.user_id][t.thread_id] = false
      end
    else
      # we build up the cache to avoid threads.length queries
      is_invisible(threads, current_user)
    end

    if params[:hide_thread]
      mark_invisible(params[:hide_thread], current_user)
      redirect_to cf_forum_url(current_forum, p: params[:p]),
        notice: t('plugins.invisible_threads.thread_marked_invisible')
      return :redirected
    end
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  inv_threads_plugin = InvisibleThreadsPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfThreadsController::MODIFY_THREADLIST_QUERY_OBJ,
                  inv_threads_plugin)
  app_controller.notification_center.
    register_hook(CfThreadsController::SHOW_THREADLIST,
                  inv_threads_plugin)
end

# eof
