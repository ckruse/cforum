# -*- encoding: utf-8 -*-

class CfForumsController < ApplicationController
  SHOW_FORUMLIST = "show_forumlist"

  def index
    if params[:t] || params[:m]
      redirect_thread
      return
    end

    # TODO: check only for selected forums
    results = CfForum.connection.
      execute("SELECT table_name, group_crit, SUM(difference) AS diff FROM counter_table WHERE table_name = 'threads' OR table_name = 'messages' GROUP BY table_name, group_crit")

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] ||= {threads: 0, messages: 0}
      @counts[r['group_crit'].to_i][r['table_name'].to_sym] = r['diff']
    end

    msgs = CfMessage.includes(:owner, thread: :forum).where("
      messages.message_id IN (
        SELECT (
          SELECT
            message_id
          FROM
            messages
          WHERE
              messages.forum_id = forums.forum_id
            AND
              deleted = false
          ORDER BY
            created_at DESC
          LIMIT 1
        )
        FROM forums
      )")

    @activities = {}
    msgs.each do |msg|
      @activities[msg.forum_id] = msg
    end

    unless current_user.blank?
      cnt = CfMessage.select('thread_id, count(*) AS cnt').
            joins("LEFT JOIN read_messages ON read_messages.message_id = messages.message_id AND read_messages.user_id = " + current_user.user_id.to_s).
            where('forum_id IN (?) AND read_messages.message_id IS NULL AND messages.created_at > ? AND deleted = false',
                  @forums.map { |f| f.forum_id }, current_user.last_sign_in_at).
            group(:thread_id).all

      @new_messages = 0

      cnt.each do |c|
        @new_messages += c.cnt
      end

      @new_threads = cnt.length
    end

    notification_center.notify(SHOW_FORUMLIST, @counts, @activities)
  end

  def redirect_archive
    redirect_to cf_archive_url(CfForum.order(:position).first)
  end

  def redirect_archive_year
    redirect_to cf_archive_year_url(CfForum.order(:position).first, params[:year])
  end

  def redirect_archive_mon
    date = Date.civil(params[:year].to_i, params[:mon].to_i, 1)
    redirect_to cf_archive_month_url(CfForum.order(:position).first, date)
  end

  def redirect_archive_thread
    thread = CfThread.where(tid: params[:tid][1..-1].to_i).all
    t = nil

    if thread.length == 1
      t = thread.first
      sort_thread(t)

    elsif thread.length > 1
      thread.each do |thr|
        sort_thread(thr)

        if thr.created_at.year == params[:year].to_i
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

    if t.nil?
      raise ActiveRecord::RecordNotFound
    else
      redirect_to cf_message_url(t, t.message), status: 301
    end
  end

  def redirect_thread
    thread = CfThread.where(tid: params[:t]).all
    raise ActiveRecord::RecordNotFound if thread.blank?

    if thread.length == 1
      thread = thread.first

      if params[:m] and message = thread.find_by_mid(params[:m].to_i)
        redirect_to cf_message_url(thread, message), status: 301
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

    if not params[:f].blank?
      forum = CfForum.where(slug: params[:f]).first
    end

    # TODO: add message
    raise ActiveRecord::RecordNotFound if forum.nil? and params[:f] != 'all'

    redirect_to cf_forum_url(forum || params[:f])
  end

  def title
    render json: {title: @title_infos}
  end
end

# eof
