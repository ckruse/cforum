class StandardPermissions < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE forums DROP COLUMN public;
      ALTER TABLE forums ADD COLUMN standard_permission CHARACTER VARYING(50) NOT NULL DEFAULT 'private';
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE forums DROP COLUMN standard_permission;
      ALTER TABLE forums ADD COLUMN public BOOLEAN NOT NULL DEFAULT false;
    SQL
  end
end

# eof
