class ForumsController < ApplicationController
  def index
    if params[:t] || params[:m]
      redirect_thread
      return
    end

    @activities = {}
    @overview_threads = []
    @forums.each do |f|
      threads = f.threads
                  .preload(:forum, messages: :owner)
                  .order(latest_message: :desc)
                  .where(deleted: false)
                  .limit(3)
                  .all

      threads = leave_out_invisible(threads).to_a

      threads.each do |thread|
        not_deleted = thread.messages.select { |m| m.deleted == false }
        thread.attribs[:latest_message] = not_deleted.max_by(&:created_at)
        thread.attribs[:first] = not_deleted.min_by(&:created_at)
      end

      @activities[f.forum_id] = threads
      @overview_threads += threads
    end

    @open_threads = CfThread
                      .preload(:forum, messages: :owner)
                      .where(thread_id: CfThread
                               .joins(:messages)
                               .where(archived: false, deleted: false, messages: { deleted: false })
                               .where(forum_id: @forums)
                               .where("(messages.flags->>'no-answer-admin' = 'no' OR " \
                                      "  (messages.flags->>'no-answer-admin') IS NULL) AND " \
                                      "(messages.flags->>'no-answer' = 'no' OR " \
                                      "  (messages.flags->>'no-answer') IS NULL)")
                               .group('threads.thread_id')
                               .having('COUNT(*) <= 1'))
                      .order(latest_message: :desc)
                      .limit(5)

    @open_threads = leave_out_invisible(@open_threads)

    @open_threads.each do |thread|
      thread.attribs[:latest_message] = thread.messages.first
      thread.attribs[:first] = thread.messages.first
    end

    gather_portal_infos if current_user.present?
    forum_list_read(@overview_threads, @activities)

    return if current_user.blank?

    @overview_threads.each do |thread|
      not_deleted_and_unread = thread
                                 .messages
                                 .select { |m| m.deleted == false && !m.attribs['classes'].include?('visited') }
      thread.attribs[:first_unread] = not_deleted_and_unread.min_by(&:created_at)
    end
  end

  def gather_portal_infos
    cnt = Message.select('thread_id, count(*) AS cnt')
            .joins('LEFT JOIN read_messages ON read_messages.message_id = messages.message_id AND ' \
                   '  read_messages.user_id = ' + current_user.user_id.to_s)
            .where('forum_id IN (?) AND read_messages.message_id IS NULL AND messages.created_at > ? AND ' \
                   '  deleted = false',
                   @forums.map(&:forum_id), current_user.last_sign_in_at)
            .group(:thread_id).all

    @new_messages = 0

    cnt.each do |c|
      @new_messages += c.cnt
    end

    @new_threads = cnt.length

    @mails = PrivMessage.where(owner_id: current_user.user_id,
                               is_read: false)
               .order(created_at: :desc)
               .limit(5)
               .all
    @mails_cnt = PrivMessage.where(owner_id: current_user.user_id,
                                   is_read: false)
                   .count

    @notifications = Notification.where(recipient_id: current_user.user_id,
                                        is_read: false)
                       .order(created_at: :desc).all
  end

  def redirect_archive
    redirect_to cf_archive_url(Forum.order(:position).first)
  end

  def redirect_archive_year
    redirect_to cf_archive_year_url(Forum.order(:position).first, params[:year])
  end

  def redirect_archive_mon
    date = Date.civil(params[:year].to_i, params[:mon].to_i, 1)
    redirect_to cf_archive_month_url(Forum.order(:position).first, date)
  end

  def redirect_archive_thread
    thread = CfThread.where(tid: params[:tid][1..-1].to_i).all
    t = nil
    year = params[:year].gsub(/_\d/, '').to_i

    if thread.length == 1
      t = thread.first
      sort_thread(t)

    elsif thread.length > 1
      thread.each do |thr|
        sort_thread(thr)

        if thr.created_at.year == year
          t = thr
          break
        end
      end

      if t.nil?
        @threads = thread
        render 'redirect_archive'
        return
      end
    end

    raise ActiveRecord::RecordNotFound if t.nil?

    redirect_to message_url(t, t.message), status: 301
  end

  def redirect_thread
    thread = CfThread.where(tid: params[:t]).all
    raise ActiveRecord::RecordNotFound if thread.blank?

    if thread.length == 1
      thread = thread.first

      if params[:m] && (message = thread.find_by_mid(params[:m].to_i)) # rubocop:disable Rails/DynamicFindBy
        redirect_to message_url(thread, message), status: 301
      else
        redirect_to cf_thread_url(thread), status: 301
      end

    else
      @threads = thread
      @threads.each do |thr|
        sort_thread(thr)
      end

      render 'redirect_archive'
      return
    end
  end

  def redirector
    forum = nil

    forum = Forum.where(slug: params[:f]).first if params[:f].present?

    # TODO: add message
    raise ActiveRecord::RecordNotFound if forum.nil? && (params[:f] != 'all')

    redirect_to forum_url(forum || params[:f])
  end

  def title
    render json: { title: @title_infos }
  end

  def stats
    @stats = ForumStat
               .select("DATE_TRUNC('month', moment) AS moment, SUM(threads) AS threads, SUM(messages) AS messages")
               .group("DATE_TRUNC('month', moment)")
               .order("DATE_TRUNC('month', moment)")
               .where("DATE_TRUNC('month', moment) < DATE_TRUNC('month', NOW())")

    @stats = if current_forum.blank?
               @stats.where('forum_id IN (?)', Forum.visible_forums(current_user).select(:forum_id))
             else
               @stats.where(forum_id: current_forum.forum_id)
             end

    @stats = @stats.to_a

    @num_messages = @stats.map(&:messages).sum
    @num_threads = @stats.map(&:threads).sum

    start = Time.now.utc.beginning_of_month - 13.months
    stop = Time.now.utc.beginning_of_month - 1
    @users_twelve_months = Message
                             .select("DATE_TRUNC('month', created_at) AS moment, COUNT(DISTINCT author) cnt")
                             .where('created_at BETWEEN ? AND ?', start, stop)
                             .group("DATE_TRUNC('month', created_at)")

    @users_twelve_months = if current_forum
                             @users_twelve_months.where(forum_id: current_forum.forum_id)
                           else
                             @users_twelve_months.where('forum_id IN (?)',
                                                        Forum.visible_forums(current_user).select(:forum_id))
                           end

    @status = {
      today: forum_state(Time.zone.now.beginning_of_day, Time.zone.now.end_of_day, current_forum),
      last_week: forum_state((Time.zone.now - 7.days).beginning_of_day,
                             (Time.zone.now - 7.days).end_of_day, current_forum),
      week: forum_state((Time.zone.now - 7.days).beginning_of_day, Time.zone.now.end_of_day, current_forum),
      month: forum_state((Time.zone.now - 30.days).beginning_of_day, Time.zone.now.end_of_day, current_forum),
      year: forum_state((Time.zone.now - 360.days).beginning_of_day, Time.zone.now.end_of_day, current_forum)
    }
  end

  def message_redirect
    msg = Message.preload(thread: :forum).find(params[:id])
    redirect_to message_url(msg.thread, msg)
  end

  private

  def forum_state(start, stop, forum = nil)
    retval = {
      threads: 0,
      messages: 0,
      num_users: 0,
      tags: [],
      users: []
    }
    num_threads_messages = Message
                             .select('COUNT(*) AS msgs, ' \
                                     'COUNT(DISTINCT thread_id) AS threads, ' \
                                     'COUNT(DISTINCT author) AS num_users')
                             .where('created_at BETWEEN ? AND ? AND deleted = false', start, stop)

    tags = Message
             .select('tag_id, COUNT(*) AS cnt')
             .joins(:message_tags)
             .where('created_at BETWEEN ? AND ? AND deleted = false', start, stop)
             .group('tag_id')
             .order('COUNT(*) DESC')
             .limit(5)

    users = Message
              .preload(:owner)
              .select('user_id, COUNT(*) AS cnt')
              .where('created_at BETWEEN ? AND ? AND deleted = false AND user_id IS NOT NULL', start, stop)
              .group('user_id')
              .order('COUNT(*) DESC')
              .limit(5)

    if forum
      num_threads_messages = num_threads_messages.where(forum_id: forum.forum_id)
      tags = tags.where(forum_id: forum.forum_id)
      users = users.where(forum_id: forum.forum_id)
    else
      fids = Forum.visible_forums(current_user).select(:forum_id)
      num_threads_messages = num_threads_messages.where('forum_id IN (?)', fids)
      tags = tags.where('forum_id IN (?)', fids)
      users = users.where('forum_id IN (?)', fids)
    end

    num_threads_messages = num_threads_messages.all.to_a[0]

    retval[:threads] = num_threads_messages.threads
    retval[:messages] = num_threads_messages.msgs
    retval[:num_users] = num_threads_messages.num_users

    tag_ids = []
    tags.each do |message|
      tag_ids << [message.tag_id, message.cnt]
    end

    tags = Tag.preload(:forum).where(tag_id: tag_ids.map { |tid| tid[0] }).all.to_a
    tag_ids.each do |tid|
      tag = tags.find { |tg| tg.tag_id == tid[0] }
      retval[:tags] << [tag, tid[1]]
    end

    retval[:users] = users.all

    retval
  end
end

# eof
