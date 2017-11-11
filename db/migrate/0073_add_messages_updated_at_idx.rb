class AddMessagesUpdatedAtIdx < ActiveRecord::Migration
  def up
    execute <<~SQL
      CREATE INDEX messages_updated_at_idx ON messages(updated_at);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX messages_updated_at_idx;
    SQL
  end
end

# eof
