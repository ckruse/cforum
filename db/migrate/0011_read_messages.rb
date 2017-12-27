class ReadMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE read_messages (
        read_message_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE UNIQUE INDEX read_messages_message_id_user_id_idx ON read_messages (message_id, user_id);
    SQL
  end

  def down
    drop_table 'read_messages'
  end
end

# eof
