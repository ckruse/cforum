class ModifySortIndexForForums < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE INDEX messages_forum_id_created_at_idx ON messages (forum_id, created_at);
      DROP INDEX messages_forum_id_updated_at_idx;
    SQL
  end

  def down
    execute <<~SQL
      CREATE INDEX messages_forum_id_updated_at_idx ON messages (forum_id, updated_at);
      DROP INDEX messages_forum_id_created_at_idx;
    SQL
  end
end

# eof
