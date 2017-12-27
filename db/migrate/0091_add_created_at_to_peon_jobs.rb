class AddCreatedAtToPeonJobs < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE peon_jobs ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
      ALTER TABLE peon_jobs ALTER COLUMN created_at DROP DEFAULT;

      ALTER TABLE peon_jobs ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
      ALTER TABLE peon_jobs ALTER COLUMN updated_at DROP DEFAULT;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE peon_jobs DROP COLUMN created_at;
      ALTER TABLE peon_jobs DROP COLUMN updated_at;
    SQL
  end
end

# eof
