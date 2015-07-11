# -*- coding: utf-8 -*-

class InvisibleThreadsPlugin < Plugin
  def modify_threadlist_query_obj()
    return if current_user.blank? or get('view_all')

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
      cache = @app_controller.get_cached_entry(:invisible, current_user.user_id) || {}

      threads.each do |t|
        cache[t.thread_id] = false
      end

      @app_controller.set_cached_entry(:invisible, current_user.user_id, cache)
    else
      # we build up the cache to avoid threads.length queries
      is_invisible(threads, current_user)
    end
  end
  alias show_archive_threadlist show_threadlist

  def show_invisible_threadlist(threads)
    cache = @app_controller.get_cached_entry(:invisible, current_user.user_id) || {}

    threads.each do |t|
      cache[t.thread_id] = true
    end

    @app_controller.set_cached_entry(:invisible, current_user.user_id, cache)
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
  app_controller.notification_center.
    register_hook(CfThreads::InvisibleController::SHOW_INVISIBLE_THREADLIST,
                  inv_threads_plugin)
  app_controller.notification_center.
    register_hook(CfArchiveController::SHOW_ARCHIVE_THREADLIST,
                  inv_threads_plugin)
end

# eof
