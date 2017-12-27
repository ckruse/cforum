class AddOrderToForums < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE forums ADD COLUMN position INTEGER NOT NULL DEFAULT 0;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE forums DROP COLUMN position;
    SQL
  end
end

# eof
