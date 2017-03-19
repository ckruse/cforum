#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

forums = Forum.all
forums.each do |f|
  puts 'Cleaning: ' + f.name
  Forum.connection.execute("SELECT counter_table_get_count('threads', " + f.forum_id.to_s + ')')
  Forum.connection.execute("SELECT counter_table_get_count('messages', " + f.forum_id.to_s + ')')
end

# eof
