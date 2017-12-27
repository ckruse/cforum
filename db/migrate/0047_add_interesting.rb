class AddInteresting < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE interesting_threads (
        interesting_thread_id BIGSERIAL PRIMARY KEY,
        thread_id BIGINT NOT NULL REFERENCES threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,

        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL,

        UNIQUE(thread_id, user_id)
      );
    SQL
  end

  def down
    drop_table 'interesting_threads'
  end
end

# eof
