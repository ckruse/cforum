class ChangeAuditingRelation < ActiveRecord::Migration
  def up
    execute <<~SQL
      ALTER TABLE auditing ALTER COLUMN relation TYPE character varying(120);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE auditing ALTER COLUMN relation TYPE regclass;
    SQL
  end
end

# eof
