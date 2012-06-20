def threads_path
  root_path
end
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
  thread.id + "/" + message.mid
end
def edit_message_path(thread, message)
  thread.id + "/" + message.mid + "/edit"
end
def new_message_path(thread)
  thread.id + "/new"
end



# eof
