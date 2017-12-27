class AddProblematicSite < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN problematic_site character varying;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE cites DROP COLUMN problematic_site;
    SQL
  end
end

# eof
