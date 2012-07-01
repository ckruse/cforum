module UrlHelpers
  def cf_thread_path(thread)
    thread.id
  end
  def edit_cf_thread_path(thread)
    cf_thread_path(thread) + '/edit'
  end

  def cf_message_path(thread, message)
    cf_thread_path(thread) + "/" + message.id
  end
  def cf_edit_message_path(thread, message)
    cf_message_path(thread, message) + "/edit"
  end
  def new_cf_message_path(thread, message)
    cf_message_path(thread, message) + "/new"
  end

end

# eof
