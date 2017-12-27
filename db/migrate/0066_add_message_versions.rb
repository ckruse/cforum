class AddMessageVersions < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE message_versions (
        message_version_id BIGSERIAL NOT NULL PRIMARY KEY,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        subject TEXT NOT NULL,
        content TEXT NOT NULL,
        user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE message_versions;
    SQL
  end
end

# eof
