class CfThreads::OpenCloseController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  include ThreadsHelper

  def open
    @thread, @id = get_thread
    check_existance_and_delete_or_set(@thread.thread_id, 'open')

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread) }
      format.json { render json: { status: :success, slug: @thread.slug } }
    end
  end

  def close
    @thread, @id = get_thread
    check_existance_and_delete_or_set(@thread.thread_id, 'closed')

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread) }
      format.json { render json: { status: :success, slug: @thread.slug } }
    end
  end

  def open_all
    index_threads

    @threads.each do |t|
      check_existance_and_delete_or_set(t.thread_id, 'open')
    end

    redirect_to cf_return_url
  end

  def close_all
    index_threads

    @threads.each do |t|
      check_existance_and_delete_or_set(t.thread_id, 'closed')
    end

    redirect_to cf_return_url
  end

  def check_existance_and_delete_or_set(tid, state)
    tid = tid.to_i.to_s

    CfThread.transaction do
      rslt = CfThread.connection.execute(
        'SELECT thread_id, state FROM opened_closed_threads WHERE thread_id = ' +
        tid +
        ' AND user_id = ' +
        current_user.user_id.to_s +
        ' FOR UPDATE'
      )

      if rslt.ntuples.zero?
        if uconf('open_close_default') != state || uconf('open_close_close_when_read') == 'yes'
          CfThread.connection.execute('INSERT INTO opened_closed_threads (user_id, thread_id, state) VALUES (' +
            current_user.user_id.to_s +
            ', ' +
            tid +
            ", '" + state + "')")
        end
      elsif rslt.first['state'] != state
        CfThread.connection.execute(
          'DELETE FROM opened_closed_threads WHERE user_id = ' +
          current_user.user_id.to_s +
          ' AND thread_id = ' +
          tid
        )
      end
      # CfThreads.transaction
    end
    # def check_existance_and_delete_or_set
  end
end

# eof
