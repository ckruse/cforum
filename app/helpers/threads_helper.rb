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
    conditions[:messages] = {deleted: false} unless @view_all

    order = uconf('sort_threads', 'descending')
    case order
    when 'ascending'
      order = 'threads.created_at ASC'
    when 'newest-first'
      order = 'threads.latest_message DESC'
    else
      order = 'threads.created_at DESC'
    end

    # the „no forum” case is much more complex; we have to do it partly manually
    # to avoid DISTINCT
    sql = "SELECT thread_id FROM threads "
    crits = []

    if forum
      crits << "forum_id = " + forum.forum_id.to_s
      crits << "deleted = false" unless @view_all
    else
      if current_user and current_user.admin?
        crits = []

      else
        crits << "forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = " + current_user.user_id.to_s + ")" if current_user
        crits << "forum_id IN (SELECT forum_id FROM forums WHERE standard_permission IN ('" +
          CfForumGroupPermission::ACCESS_READ + "','" +
          CfForumGroupPermission::ACCESS_WRITE +
          (current_user ? ("', '" +
                           CfForumGroupPermission::ACCESS_KNOWN_WRITE + "','" +
                           CfForumGroupPermission::ACCESS_KNOWN_READ) : ""
          ) +
          "'))"

        crits = ["(" + crits.join(" OR ") + ")"]
      end

      unless @view_all
        crits << 'threads.deleted = false'
      end
    end
    sql << ' WHERE ' + crits.join(" AND ") unless crits.empty?
    sql << " ORDER BY threads.sticky DESC, #{order} LIMIT #{@limit} OFFSET #{@limit * @page}"

    @threads = CfThread.
               preload(:forum, messages: [:owner, :tags, :close_vote, :open_vote]).
               includes(messages: :owner).
               where(conditions).
               where("threads.thread_id IN (#{sql})").
               order("threads.sticky DESC, #{order}")

    if forum
      rslt = CfForum.connection.execute("SELECT counter_table_get_count('threads', " +
                                        current_forum.forum_id.to_s +
                                        ") AS cnt")
    else
      rslt = CfForum.connection.execute("SELECT SUM(difference) AS cnt FROM counter_table WHERE table_name = 'threads'")
    end

    @all_threads_count = rslt[0]['cnt'].to_i

    ret = notification_center.notify(CfThreadsController::MODIFY_THREADLIST_QUERY_OBJ)
    ret.each do |b|
      next if b.blank?
      @threads = b.call(@threads)
    end

    @threads
  end
end
