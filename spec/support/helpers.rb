def thread_params_from_slug(thread)
  hsh = { curr_forum: thread.forum.slug }

  if thread.slug =~ %r{^/(\d+)/(\w+)/(\d+)/([^/]+)}
    hsh[:year] = Regexp.last_match(1)
    hsh[:mon] = Regexp.last_match(2)
    hsh[:day] = Regexp.last_match(3)
    hsh[:tid] = Regexp.last_match(4)
  end

  hsh
end

def message_params_from_slug(message, thread = nil)
  thread = message.thread if thread.blank?
  hsh = thread_params_from_slug(thread)
  hsh[:mid] = message.message_id.to_s

  hsh
end

# eof
