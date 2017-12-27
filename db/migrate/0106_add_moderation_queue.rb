class AddModerationQueue < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE moderation_queue (
        moderation_queue_entry_id BIGSERIAL PRIMARY KEY,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        cleared BOOLEAN NOT NULL DEFAULT false,
        reported INT NOT NULL,

        reason CHARACTER VARYING NOT NULL,
        duplicate_url CHARACTER VARYING,
        custom_reason CHARACTER VARYING,

        resolution TEXT,
        resolution_action CHARACTER VARYING(250),

        closer_name CHARACTER VARYING(255),
        closer_id INT REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,

        created_at TIMESTAMP WITHOUT TIME ZONE,
        updated_at TIMESTAMP WITHOUT TIME ZONE
      );

      CREATE UNIQUE INDEX ON moderation_queue(message_id) WHERE cleared = true;
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE moderation_queue;
    SQL
  end
end

# eof
