class CreateForumThreadsTriggers < ActiveRecord::Migration[5.0]
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../count_threads.sql')
    execute sql
  end

  def down
    execute <<-SQL
      DROP FUNCTION count_threads_insert_trigger() CASCADE;
      DROP FUNCTION count_threads_delete_trigger() CASCADE;
      DROP FUNCTION count_threads_truncate_trigger() CASCADE;
      DROP FUNCTION count_threads_insert_forum_trigger() CASCADE;
    SQL
  end
end

# eof
