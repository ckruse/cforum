class CreateForumMessageTriggers < ActiveRecord::Migration
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../count_messages.sql')
    execute sql
  end

  def down
    execute <<-SQL
      DROP FUNCTION count_messages_insert_trigger() CASCADE;
      DROP FUNCTION count_messages_delete_trigger() CASCADE;
      DROP FUNCTION count_messages_truncate_trigger() CASCADE;
      DROP FUNCTION count_messages_insert_forum_trigger() CASCADE;
    SQL
  end
end

# eof
