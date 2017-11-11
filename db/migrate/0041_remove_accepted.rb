class RemoveAccepted < ActiveRecord::Migration
  def up
    execute <<~SQL
      UPDATE messages SET flags = flags || '"accepted" => "yes"'::hstore WHERE accepted = true;
      ALTER TABLE messages DROP COLUMN accepted;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN accepted BOOLEAN NOT NULL DEFAULT false;
      UPDATE messages SET accepted = true WHERE flags->'accepted' = "yes";
    SQL
  end
end

# eof
