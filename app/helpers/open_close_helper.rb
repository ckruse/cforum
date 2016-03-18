# -*- coding: utf-8 -*-

module OpenCloseHelper
  def open_close_threadlist(threads)
    return unless current_user
    return if view_all or params[:fold] == 'false'

    # default state is setable via user config
    default_state   = uconf('open_close_default')
    close_when_read = uconf('open_close_close_when_read') == 'yes'

    # now continue with the checks for each thread

    ids = []
    thread_map = {}

    threads.each do |t|
      ids << t.thread_id
      thread_map[t.thread_id.to_s] = t
      t.attribs['open_state'] = default_state

      if close_when_read
        mids = t.sorted_messages.map { |m| m.message_id }
        rslt = is_read(current_user.user_id, mids)

        t.attribs['open_state'] = 'closed' if not rslt.blank? and rslt.length == mids.length
      end

      t.message.attribs['classes'] << t.attribs['open_state']
    end

    if not ids.blank?
      result = CfThread.connection.execute("SELECT thread_id, state FROM opened_closed_threads WHERE thread_id IN (" + ids.join(", ") + ") AND user_id = " + current_user.user_id.to_s)
      result.each do |row|
        thread_map[row['thread_id']].attribs['open_state'] = row['state'] if thread_map[row['thread_id']]
      end
    end
  end
end

# eof