module UrlHelpers
  def cf_forum_path(forum)
    return forum.slug
  end

  def cf_thread_path(thread)
    cf_forum_path(thread.forum) + thread.slug
  end
  def edit_cf_thread_path(thread)
    cf_thread_path(thread) + '/edit'
  end

  def cf_message_path(thread, message)
    cf_thread_path(thread) + "/" + message.id.to_s
  end
  def cf_edit_message_path(thread, message)
    cf_message_path(thread, message) + "/edit"
  end
  def new_cf_message_path(thread, message)
    cf_message_path(thread, message) + "/new"
  end

  def cf_thread_url(thread)
    root_url + thread.slug[1..-1]
  end

  def cf_message_url(thread, message)
    cf_thread_url(thread) + '/' + message.id.to_s
  end

end

# eof
