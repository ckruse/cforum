# -*- encoding: utf-8 -*-

class CreateForumMessageTriggers  < ActiveRecord::Migration
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../count_messages.sql')
    execute sql
  end

  def down
    execute 'DROP FUNCTION cforum.count_messages_insert_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_messages_delete_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_messages_truncate_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.count_messages_insert_forum_trigger() CASCADE'
  end
end

# eof