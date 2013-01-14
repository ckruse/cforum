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


    if not current_user
      @forums = CfForum.where("standard_permission = ? OR standard_permission = ?", CfForumGroupPermission::ACCESS_READ, CfForumGroupPermission::ACCESS_WRITE).order('name ASC').all
    elsif current_user and current_user.admin
      @forums = CfForum.order('name ASC').find :all
    else
      @forums = CfForum.where(
        "(standard_permission IN (?, ?, ?, ?)) OR forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ?)",
        CfForumGroupPermission::ACCESS_READ,
        CfForumGroupPermission::ACCESS_WRITE,
        CfForumGroupPermission::ACCESS_KNOWN_READ,
        CfForumGroupPermission::ACCESS_KNOWN_WRITE,
        current_user.user_id
      ).order('name ASC')
    end

    # TODO: check only for selected forums
    results = CfForum.connection.execute("SELECT table_name, group_crit, SUM(difference) AS diff FROM counter_table WHERE table_name = 'threads' OR table_name = 'messages' GROUP BY table_name, group_crit")

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] ||= {threads: 0, messages: 0}
      @counts[r['group_crit'].to_i][r['table_name'].to_sym] = r['diff']
    end

    msgs = CfMessage.includes(:owner, :thread => :forum).where("
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
      )").all

    @activities = {}
    msgs.each do |msg|
      @activities[msg.forum_id] = msg
    end

    notification_center.notify(SHOW_FORUMLIST, @threads, false)
  end

  def redirect_archive
    thread = CfThread.find_by_tid(params[:tid][1..-1].to_i)
    if thread
      redirect_to cf_thread_url(thread), status: 301
    else
      raise CForum::NotFoundException.new # TODO: add message
    end
  end
end

# eof
