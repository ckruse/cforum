module UrlHelpers
  def cf_thread_path(thread)
    thread.id[1..-1]
  end
  def edit_cf_thread_path(thread)
    thread.id[1..-1] + '/edit'
  end

  def cf_message_path(thread, message)
    cf_thread_path(thread) + "/" + message.id
  end
  def cf_edit_message_path(thread, message)
    cf_message_path(thread, message) + "/edit"
  end
  def cf_new_message_path(thread, message)
    cf_message_path(thread, message) + "/new"
  end

end

# eof
