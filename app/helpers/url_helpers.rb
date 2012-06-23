module UrlHelpers

  def threads_path(thread=nil)
    root_path
  end

  alias :c_forum_threads_path :threads_path

  def thread_path(thread)
    thread.id
  end
  def edit_thread_path(thread)
    thread.id + '/edit'
  end
  def new_thread_path
    '/new'
  end

  def messages_path(thread)
    thread.id
  end
  def message_path(thread, message)
    thread.id + "/" + message.id
  end
  def edit_message_path(thread, message)
    thread.id + "/" + message.id + "/edit"
  end
  def new_message_path(thread)
    thread.id + "/new"
  end

end

# eof
