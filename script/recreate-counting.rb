#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

Forum.transaction do
  # correct all deleted flags for threads
  Forum.connection.execute('UPDATE cforum.threads SET deleted = (' \
                           '  SELECT NOT EXISTS(SELECT message_id FROM cforum.messages ' \
                           '  WHERE thread_id = threads.thread_id AND deleted = false))')

  # delete existing entries
  Forum.connection.execute("DELETE FROM cforum.counter_table WHERE table_name = 'threads' OR table_name = 'messages'")

  # recreate base entries
  forums = Forum.all
  forums.each do |f|
    Forum.connection.execute(
      "INSERT INTO cforum.counter_table (table_name, group_crit, difference) VALUES ('messages', " +
      f.forum_id.to_s +
      ', 0)'
    )
    Forum.connection.execute(
      "INSERT INTO cforum.counter_table (table_name, group_crit, difference) VALUES ('threads', " +
      f.forum_id.to_s +
      ', 0)'
    )
  end

  results = Forum.connection.execute('SELECT forum_id, COUNT(*) AS cnt FROM cforum.messages ' \
                                     '  WHERE deleted = false GROUP BY forum_id')
  results.each do |r|
    next if r['cnt'] == '0'

    Forum.connection.execute(
      "INSERT INTO cforum.counter_table (table_name, group_crit, difference) VALUES ('messages', " +
      r['forum_id'] +
      ', ' +
      r['cnt'] +
      ')'
    )
  end

  results = Forum.connection.execute('SELECT forum_id, COUNT(*) AS cnt FROM cforum.threads ' \
                                     '  WHERE deleted = false GROUP BY forum_id')
  results.each do |r|
    next if r['cnt'] == '0'

    Forum.connection.execute(
      "INSERT INTO cforum.counter_table (table_name, group_crit, difference) VALUES ('threads', " +
      r['forum_id'] +
      ', ' +
      r['cnt'] +
      ')'
    )
  end
end

# eof
