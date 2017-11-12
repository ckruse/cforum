module InvisibleHelper
  include CacheHelper

  def mark_invisible(user, thread)
    return if user.blank?
    thread = [thread] unless thread.is_a?(Array)

    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }
    user_id = user.is_a?(User) ? user.user_id : user

    sql = 'INSERT INTO invisible_threads (user_id, thread_id) VALUES (' + user_id.to_s + ', '

    thread.each do |t|
      begin
        Message.connection.execute(sql + t.to_s + ')')
      rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
      end
    end

    thread
  end

  def mark_visible(user, thread)
    return if user.blank?
    thread = [thread] unless thread.is_a?(Array)

    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }
    user_id = user.is_a?(User) ? user.user_id : user

    sql = 'DELETE FROM invisible_threads WHERE user_id = ' +
          user_id.to_s + ' AND thread_id = '

    CfThread.transaction do
      thread.each do |t|
        Message.connection.execute(sql + t.to_s)
      end
    end
  end

  def invisible?(user, thread, invalidate_cache = false)
    return if user.blank?

    thread = [thread] if !thread.is_a?(Array) && !thread.is_a?(ActiveRecord::Relation)
    thread = thread.map { |t| t.is_a?(CfThread) ? t.thread_id : t.to_i }

    user_id = user.is_a?(User) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:invisible, user_id) || {}
    cache = {} if invalidate_cache

    if cache
      has_all = true
      retval = []

      thread.each do |t|
        if !cache.key?(t)
          has_all = false
        elsif cache[t]
          retval << t
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

    # TODO: this smells…
    result = CfThread.connection.execute('SELECT thread_id FROM invisible_threads WHERE ' \
                                         '  thread_id IN (' + thread.join(', ') + ') AND user_id = ' + user_id.to_s)
    result.each do |row|
      t = row['thread_id']
      invisible_threads << t
      new_cache[t] = true
    end

    merge_cached_entry(:invisible, user_id, new_cache)

    invisible_threads
  end

  def leave_out_invisible(threads)
    return threads if current_user.blank? || @view_all
    @invisible_modified = true
    threads.where('NOT EXISTS(SELECT thread_id FROM invisible_threads ' \
                  '  WHERE user_id = ? AND invisible_threads.thread_id = threads.thread_id)',
                  current_user.user_id)
  end

  def leave_out_invisible_for_threadlist(threads)
    return unless current_user

    # when we modified the query object we know that there can't be
    # any invisible threads; so avoid the extra work and just mark
    # them all as visible in the cache
    if @invisible_modified
      cache = get_cached_entry(:invisible, current_user.user_id) || {}

      threads.each do |t|
        cache[t.thread_id] = false
      end

      set_cached_entry(:invisible, current_user.user_id, cache)
    else
      # we build up the cache to avoid threads.length queries
      invisible?(current_user, threads)
    end
  end
end

# eof
