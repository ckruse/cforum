module UrlHelpers

  def threads_path(thread=nil)
    root_path
  end

  alias :cf_threads_path :threads_path

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
    raise message.inspect unless message.id.is_a?(String)
    thread.id + "/" + message.id
  end
  def edit_message_path(thread, message)
    thread.id + "/" + message.id + "/edit"
  end
  def new_message_path(thread, message)
    thread.id + "/" + message.id + "/new"
  end

end

# eof
