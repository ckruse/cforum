class AddAuthorToPrivMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE priv_messages ADD COLUMN sender_name CHARACTER VARYING;
      ALTER TABLE priv_messages ADD COLUMN recipient_name CHARACTER VARYING;

      UPDATE priv_messages SET sender_name = (SELECT username FROM users WHERE user_id = sender_id);
      UPDATE priv_messages SET recipient_name = (SELECT username FROM users WHERE user_id = recipient_id);

      DELETE FROM priv_messages WHERE sender_id IS NULL;
      DELETE FROM priv_messages WHERE recipient_id IS NULL;

      ALTER TABLE priv_messages ALTER COLUMN sender_name SET NOT NULL;
      ALTER TABLE priv_messages ALTER COLUMN recipient_name SET NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE priv_messages DROP COLUMN sender_name;
      ALTER TABLE priv_messages DROP COLUMN recipient_name;
    SQL
  end
end

# eof
