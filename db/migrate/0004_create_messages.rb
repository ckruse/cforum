class CreateMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TABLE messages (
        message_id BIGSERIAL NOT NULL PRIMARY KEY,
        thread_id BIGINT NOT NULL REFERENCES threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,

        upvotes INTEGER NOT NULL DEFAULT 0,
        downvotes INTEGER NOT NULL DEFAULT 0,
        deleted BOOLEAN NOT NULL DEFAULT false,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        mid BIGINT,

        user_id BIGINT REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        parent_id BIGINT REFERENCES messages (message_id) ON DELETE SET NULL ON UPDATE CASCADE,

        author CHARACTER VARYING NOT NULL,
        email CHARACTER VARYING,
        homepage CHARACTER VARYING,

        subject CHARACTER VARYING NOT NULL,
        content CHARACTER VARYING NOT NULL,

        flags JSONB
      );

      ALTER TABLE threads ADD COLUMN message_id BIGINT REFERENCES messages (message_id) ON DELETE SET NULL ON UPDATE CASCADE;
      CREATE INDEX threads_message_id_idx on threads (message_id); -- used for the FKs

      CREATE INDEX messages_thread_id_idx ON messages (thread_id);
      CREATE INDEX messages_mid_idx ON messages (mid);

      CREATE INDEX messages_parent_id_idx ON messages (parent_id); -- FK index

      CREATE INDEX messages_forum_id_updated_at_idx ON messages (forum_id, updated_at);
      CREATE INDEX messages_user_id_idx on messages (user_id);
    SQL
  end

  def down
    remove_column 'threads', :message_id
    drop_table 'messages'
  end
end
