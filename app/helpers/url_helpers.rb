module UrlHelpers
  def query_string(args = {})
    qs = []
    args.each do |k, v|
      qs << URI.escape(k.to_s) + "=" + URI.escape(v.to_s)
    end

    return '?' + qs.join("&") unless qs.blank?
    ''
  end

  def cf_forum_path(forum, args = {})
    forum = forum.slug unless forum.is_a?(String)
    root_path + forum + query_string(args)
  end

  def cf_thread_path(thread, args = {})
    cf_forum_path(thread.forum) + thread.slug + query_string(args)
  end
  def edit_cf_thread_path(thread, args = {})
    cf_thread_path(thread) + '/edit' + query_string(args)
  end

  def cf_message_path(thread, message, args = {})
    cf_thread_path(thread) + "/" + message.id.to_s + query_string(args)
  end
  def cf_edit_message_path(thread, message, args = {})
    cf_message_path(thread, message) + "/edit" + query_string(args)
  end
  def new_cf_message_path(thread, message, args = {})
    cf_message_path(thread, message) + "/new" + query_string(args)
  end

  def cf_forum_url(forum, args = {})
    forum = forum.slug unless forum.is_a?(String)
    return root_url + forum + query_string(args)
  end

  def cf_thread_url(thread, args = {})
    cf_forum_url(thread.forum) + thread.slug + query_string(args)
  end

  def cf_message_url(thread, message, args = {})
    cf_thread_url(thread) + '/' + message.id.to_s + query_string(args)
  end

end

# eof
