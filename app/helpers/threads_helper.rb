module ThreadsHelper
  def get_threads(forum, order = 'threads.created_at DESC', user = current_user, with_sticky = false, thread_conditions = {})
    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false if conf('use_archive') == 'yes'

    unless @view_all
      conditions[:deleted] = false
      conditions[:messages] = {deleted: false}
    end

    conditions.merge!(thread_conditions)

    @sticky_threads = nil
    @threads = CfThread.
               preload(:forum, messages: [:owner, :tags, votes: :voters]).
               includes(messages: :owner).
               where(conditions)

    if with_sticky
      @threads = @threads.where(sticky: false)
      @sticky_threads = CfThread.
                        preload(:forum, messages: [:owner, :tags, votes: :voters]).
                        includes(messages: :owner).
                        where(conditions).
                        where(sticky: true)
    end

    if forum
      @threads = @threads.where(forum_id: forum.forum_id)
      @sticky_threads = @sticky_threads.where(forum_id: forum.forum_id) if with_sticky
    else
      if not user or not user.admin?
        crits = []
        crits << "threads.forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = " + user.user_id.to_s + ")" if user
        crits << "threads.forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
          CfForumGroupPermission::ACCESS_READ + "','" +
          CfForumGroupPermission::ACCESS_WRITE +
          (user ? ("', '" +
                   CfForumGroupPermission::ACCESS_KNOWN_WRITE + "','" +
                   CfForumGroupPermission::ACCESS_KNOWN_READ) : ""
          ) +
          "'))"

        @threads = @threads.where(crits.join(" OR "))
        @sticky_threads = @sticky_threads.where(crits.join(" OR ")) if with_sticky
      end
    end

    @threads = @threads.order(order)
    @sticky_threads = @sticky_threads.order(order) if with_sticky

    ret = notification_center.notify(CfThreadsController::MODIFY_THREADLIST_QUERY_OBJ)
    ret.each do |b|
      next if b.blank?
      @threads = b.call(@threads)
      @sticky_threads = b.call(@sticky_threads) if with_sticky
    end

    [@sticky_threads, @threads]
  end

  def index_threads(with_sticky = true)
    forum  = current_forum

    order = uconf('sort_threads')
    case order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end

    @sticky_threads, @threads = get_threads(forum, order, current_user, with_sticky)

    if uconf('page_messages') == 'yes'
      @page  = params[:p].to_i
      @limit = uconf('pagination').to_i

      @page  = 0 if @page < 0
      @limit = 50 if @limit <= 0

      @limit -= @sticky_threads.length if with_sticky

      @all_threads_count = @threads.count
      @threads = @threads.limit(@limit).offset(@limit * @page)
    end

    @threads.each do |t|
      sort_thread(t)
    end

    if with_sticky
      @sticky_threads.each do |t|
        sort_thread(t)
      end

      @threads = @sticky_threads + @threads
    end

    @threads
  end
end
