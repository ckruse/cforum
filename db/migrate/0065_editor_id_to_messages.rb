class EditorIdToMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN editor_id BIGINT
        REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages DROP COLUMN editor_id;
    SQL
  end
end

# eof
