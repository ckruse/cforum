# -*- coding: utf-8 -*-

class OpenCloseThreadPlugin < Plugin
  def show_threadlist(threads)
    return unless current_user
    return if application_controller.view_all

    # default state is setable via user config
    default_state   = uconf('open_close_default', 'open')
    close_when_read = uconf('open_close_close_when_read', 'no') == 'yes'

    is_read = get_plugin_api :is_read

    #
    # check for standard actions:
    # - close a thread
    # - open a thread
    # - close all threads
    # - open all threads
    #

    unless params[:close].blank?
      return close_thread(params[:close])
    end

    unless params[:open].blank?
      return open_thread(params[:open])
    end

    if params[:close_all] == 'yes'
      threads.each do |t|
        check_existance_and_delete_or_set(t.thread_id, 'closed')
      end

      redirect_to cf_forum_url(current_forum)
      return :redirected
    end

    if params[:open_all] == 'yes'
      threads.each do |t|
        check_existance_and_delete_or_set(t.thread_id, 'open')
      end

      redirect_to cf_forum_url(current_forum)
      return :redirected
    end

    # now continue with the checks for each thread

    ids = []
    thread_map = {}

    threads.each do |t|
      ids << t.thread_id
      thread_map[t.thread_id.to_s] = t
      t.attribs['open_state'] = default_state

      if close_when_read
        mids = t.sorted_messages.map { |m| m.message_id }
        rslt = is_read.call(mids, current_user.user_id)

        t.attribs['open_state'] = 'closed' if not rslt.blank? and rslt.length == mids.length
      end

      t.message.attribs['classes'] << t.attribs['open_state']
    end

    if not ids.blank?
      result = CfThread.connection.execute("SELECT thread_id, state FROM cforum.opened_closed_threads WHERE thread_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        thread_map[row['thread_id']].attribs['open_state'] = row['state'] if thread_map[row['thread_id']]
      end
    end
  end

  def open_thread(tid)
    check_existance_and_delete_or_set(tid, 'open')
    redirect_to cf_forum_url(current_forum)
    return :redirected
  end

  def close_thread(tid)
    check_existance_and_delete_or_set(tid, 'closed')
    redirect_to cf_forum_url(current_forum)
    return :redirected
  end

  def check_existance_and_delete_or_set(tid, state)
    tid = tid.to_i.to_s

    CfThread.transaction do
      rslt = CfThread.connection.execute(
        "SELECT thread_id, state FROM cforum.opened_closed_threads WHERE thread_id = " +
        tid +
        " AND user_id = " +
        current_user.user_id.to_s +
        " FOR UPDATE"
      )

      if rslt.ntuples == 0
        if uconf('open_close_default', 'open') != state || uconf('open_close_close_when_read', 'no') == 'yes'
          CfThread.connection.execute("INSERT INTO cforum.opened_closed_threads (user_id, thread_id, state) VALUES (" +
            current_user.user_id.to_s +
            ", " +
            tid +
            ", '" + state + "')"
          )
        end
      else
        CfThread.connection.execute(
          "DELETE FROM cforum.opened_closed_threads WHERE user_id = " +
          current_user.user_id.to_s +
          " AND thread_id = " +
          tid
        )
      end

    end # CfThreads.transaction

  end # def check_existance_and_delete_or_set
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  oc_plugin = OpenCloseThreadPlugin.new(app_controller)
  app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, oc_plugin)
end

# eof
