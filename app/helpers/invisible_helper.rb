# -*- coding: utf-8 -*-

module InvisibleHelper
  def mark_invisible(user, thread)
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

  def mark_visible(user, thread)
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

  def is_invisible(user, thread)
    return if user.blank?

    thread = [thread] if not thread.is_a?(Array) and not thread.is_a?(ActiveRecord::Relation)
    thread = thread.map {|t| t.is_a?(CfThread) ? t.thread_id : t.to_i}

    user_id = user.is_a?(CfUser) ? user.user_id : user

    new_cache = {}
    cache = get_cached_entry(:invisible, user_id) || {}

    if cache
      has_all = true
      retval = []

      thread.each do |t|
        if not cache.has_key?(t)
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

    result = CfThread.connection.execute("SELECT thread_id FROM invisible_threads WHERE thread_id IN (" + thread.join(", ") + ") AND user_id = " + user_id.to_s)
    result.each do |row|
      t = row['thread_id'].to_i
      invisible_threads << t
      new_cache[t] = true
    end

    merge_cached_entry(:invisible, user_id, new_cache)

    invisible_threads
  end
end

# eof
