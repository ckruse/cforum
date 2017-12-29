class AddFlagsForThread < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE threads ADD COLUMN flags JSONB;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE threads DROP COLUMN flags;
    SQL
  end
end

# eof
