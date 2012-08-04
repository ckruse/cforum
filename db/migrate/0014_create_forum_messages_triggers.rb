# -*- encoding: utf-8 -*-

class CreateForumMessagesTriggers  < ActiveRecord::Migration
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../count_threads.sql')
    execute sql
  end

  def down
    execute 'DROP FUNCTION cforum.count_threads_insert_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_threads_delete_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_threads_truncate_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_threads_delete_forum_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_threads_truncate_forum_trigger() CASCADE'
  end
end

# eof