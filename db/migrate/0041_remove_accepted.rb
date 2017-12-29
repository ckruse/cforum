class RemoveAccepted < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      UPDATE messages SET flags = flags || '{"accepted": "yes"}'::jsonb WHERE accepted = true;
      ALTER TABLE messages DROP COLUMN accepted;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN accepted BOOLEAN NOT NULL DEFAULT false;
      UPDATE messages SET accepted = true WHERE flags->>'accepted' = "yes";
    SQL
  end
end

# eof
