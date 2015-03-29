module ThreadsHelper
  def index_threads
    forum  = current_forum
    @page  = params[:p].to_i
    @limit = uconf('pagination', 50).to_i

    @page  = 0 if @page < 0
    @limit = 50 if @limit <= 0

    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false if conf('use_archive') == 'yes'

    unless @view_all
      conditions[:deleted] = false
      conditions[:messages] = {deleted: false}
    end

    order = uconf('sort_threads', 'descending')
    case order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end


    @threads = CfThread.
               preload(:forum, messages: [:owner, :tags, votes: :voters]).
               includes(messages: :owner).
               where(conditions)

    if forum
      @threads = @threads.where(forum_id: forum.forum_id)
    else
      if not current_user or not current_user.admin?
        crits = []
        crits << "threads.forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = " + current_user.user_id.to_s + ")" if current_user
        crits << "threads.forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
          CfForumGroupPermission::ACCESS_READ + "','" +
          CfForumGroupPermission::ACCESS_WRITE +
          (current_user ? ("', '" +
                           CfForumGroupPermission::ACCESS_KNOWN_WRITE + "','" +
                           CfForumGroupPermission::ACCESS_KNOWN_READ) : ""
          ) +
          "'))"

        @threads = @threads.where(crits.join(" OR "))
      end
    end

    @threads = @threads.order("threads.sticky DESC, #{order}")

    ret = notification_center.notify(CfThreadsController::MODIFY_THREADLIST_QUERY_OBJ)
    ret.each do |b|
      next if b.blank?
      @threads = b.call(@threads)
    end

    @all_threads_count = @threads.count
    @threads = @threads.limit(@limit).offset(@limit * @page)

    @threads.each do |t|
      sort_thread(t)
    end

    @threads
  end
end
