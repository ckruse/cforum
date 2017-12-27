class InterestingThreadsToMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE interesting_messages (
        interesting_message_id BIGSERIAL NOT NULL PRIMARY KEY,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      INSERT INTO interesting_messages (message_id, user_id, created_at, updated_at)
        SELECT
          (SELECT message_id FROM messages WHERE thread_id = interesting_threads.thread_id ORDER BY created_at ASC LIMIT 1),
             user_id,
             created_at,
             updated_at
           FROM interesting_threads;

      DROP TABLE interesting_threads;
    SQL
  end
end

# eof
