class AddInvisibleThreads < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE invisible_threads (
        invisible_thread_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        thread_id BIGINT NOT NULL REFERENCES threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE UNIQUE INDEX invisible_threads_thread_id_user_id_idx ON invisible_threads (thread_id, user_id);
    SQL
  end

  def down
    drop_table 'invisible_threads'
  end
end

# eof
