class PeonSchema < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE peon_jobs (
        peon_job_id BIGSERIAL NOT NULL PRIMARY KEY,
        queue_name CHARACTER VARYING(255) NOT NULL,
        max_tries INTEGER NOT NULL DEFAULT 0,
        tries INTEGER NOT NULL DEFAULT 0,
        work_done BOOLEAN NOT NULL DEFAULT false,
        class_name CHARACTER VARYING(250) NOT NULL,
        arguments CHARACTER VARYING NOT NULL,
        errstr CHARACTER VARYING,
        stacktrace CHARACTER VARYING
      );

      CREATE INDEX peon_jobs_work_done_idx ON peon_jobs (work_done);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE peon_jobs;
    SQL
  end
end

# eof
