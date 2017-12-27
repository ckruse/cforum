class CreateStickyCreatedAtIdx < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE INDEX threads_sticky_created_at_idx ON threads (sticky, created_at);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX threads_sticky_created_at_idx;
    SQL
  end
end

# eof
