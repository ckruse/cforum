# -*- coding: utf-8 -*-

def thread_params_from_slug(thread)
  hsh = {curr_forum: thread.forum.slug}

  if thread.slug =~ /^\/(\d+)\/(\w+)\/(\d+)\/([^\/]+)/
    hsh[:year] = $1
    hsh[:mon] = $2
    hsh[:day] = $3
    hsh[:tid] = $4
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
