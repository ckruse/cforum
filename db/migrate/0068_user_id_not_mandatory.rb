class UserIdNotMandatory < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE message_versions ALTER COLUMN user_id DROP NOT NULL;
      ALTER TABLE message_versions ADD COLUMN author TEXT;
      UPDATE message_versions SET author = (SELECT username FROM users WHERE user_id = message_versions.user_id);
      ALTER TABLE message_versions ALTER COLUMN author SET NOT NULL;

      ALTER TABLE messages ADD COLUMN edit_author TEXT;
      UPDATE messages SET edit_author = (SELECT username FROM users WHERE user_id = messages.editor_id) WHERE editor_id IS NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE message_versions ALTER COLUMN user_id SET NOT NULL;
      ALTER TABLE message_versions DROP COLUMN author;
      ALTER TABLE messages DROP COLUMN edit_author;
    SQL
  end
end

# eof
