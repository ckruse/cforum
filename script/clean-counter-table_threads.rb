#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

forums = CfForum.all
forums.each do |f|
  puts "Cleaning: " + f.name
  CfForum.connection.execute("SELECT cforum.counter_table_get_count('threads', " + f.forum_id.to_s + ")");
  CfForum.connection.execute("SELECT cforum.counter_table_get_count('messages', " + f.forum_id.to_s + ")");
end

# eof