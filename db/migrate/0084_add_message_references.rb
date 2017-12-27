class AddMessageReferences < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE message_references (
        message_reference_id BIGSERIAL PRIMARY KEY,
        src_message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        dst_message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        UNIQUE(dst_message_id, src_message_id)
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE message_references;
    SQL
  end
end

# eof
