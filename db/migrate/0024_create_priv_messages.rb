class CreatePrivMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE priv_messages (
        priv_message_id BIGSERIAL NOT NULL PRIMARY KEY,
        sender_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        recipient_id BIGINT REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        owner_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        is_read BOOLEAN NOT NULL DEFAULT false,
        subject CHARACTER VARYING(250) NOT NULL,
        body TEXT NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE INDEX priv_messages_recipient_id_idx ON priv_messages (recipient_id);
      CREATE INDEX priv_messages_sender_id_idx ON priv_messages (sender_id);
      CREATE INDEX priv_messages_owner_id_idx ON priv_messages (owner_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE priv_messages
    SQL
  end
end

# eof
