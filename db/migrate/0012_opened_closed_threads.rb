class OpenedClosedThreads < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE opened_closed_threads (
        opened_closed_thread_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        thread_id BIGINT NOT NULL REFERENCES threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE,
        state CHARACTER VARYING(10) NOT NULL
      );

      CREATE UNIQUE INDEX opened_closed_threads_thread_id_user_id_idx ON opened_closed_threads (thread_id, user_id);
    SQL
  end

  def down
    drop_table 'opened_closed_threads'
  end
end

# eof
