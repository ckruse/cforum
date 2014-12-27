# -*- encoding: utf-8 -*-

class CfForumsController < ApplicationController
  SHOW_FORUMLIST = "show_forumlist"

  def index
    if params[:t] || params[:m]
      thread = CfThread.find_by_tid(params[:t].to_i)
      if thread
        if params[:m] and message = thread.find_by_mid(params[:m].to_i)
          redirect_to cf_message_url(thread, message), status: 301
        else
          redirect_to cf_thread_url(thread), status: 301
        end
      end
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

    notification_center.notify(SHOW_FORUMLIST, @counts, @activities)
  end

  def redirect_archive
    thread = CfThread.find_by_tid(params[:tid][1..-1].to_i)

    if thread
      sort_thread(thread)
      redirect_to cf_message_url(thread, thread.message), status: 301
    else
      raise CForum::NotFoundException.new # TODO: add message
    end
  end

  def redirector
    forum = nil

    if not params[:f].blank?
      forum = CfForum.where(slug: params[:f]).first
    end

    # TODO: add message
    raise CForum::NotFoundException.new if forum.nil?

    redirect_to cf_forum_url(forum)
  end
end

# eof
