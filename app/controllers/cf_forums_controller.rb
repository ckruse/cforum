# -*- encoding: utf-8 -*-

class CfForumsController < ApplicationController
  load_and_authorize_resource

  SHOW_FORUMLIST = "show_forumlist"

  def index
    if params[:t] || params[:m]
      thread = CfThread.find_by_tid(params[:t].to_i)
      if thread
        if params[:m] and message = thread.find_message(params[:m].to_i)
          redirect_to cf_message_url(thread, message), status: 301
        else
          redirect_to cf_thread_url(thread), status: 301
        end
      end
    end


    @forums = CfForum.order('name ASC').find(:all)
    results = CfForum.connection.execute("SELECT group_crit, SUM(difference) AS diff FROM cforum.counter_table WHERE table_name = 'threads' GROUP BY group_crit")

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] = r['diff']
    end

    results = CfForum.select("forum_id, (SELECT updated_at FROM cforum.messages WHERE cforum.messages.forum_id = cforum.forums.forum_id AND deleted = false ORDER BY updated_at DESC LIMIT 1) AS updated_at")
    @activities = {}
    results.each do |row|
      @activities[row.forum_id] = row.updated_at
    end

    notification_center.notify(SHOW_FORUMLIST, @threads, false)
  end

  def redirect_archive
    thread = CfThread.find_by_tid(params[:tid][1..-1].to_i)
    if thread
      redirect_to cf_thread_url(thread), status: 301
    else
      # TODO: raise 404
    end
  end
end

# eof