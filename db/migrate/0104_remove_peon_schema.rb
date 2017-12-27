class RemovePeonSchema < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP TABLE peon_jobs;
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE peon_jobs (
          peon_job_id bigserial PRIMARY KEY,
          queue_name character varying(255) NOT NULL,
          max_tries integer DEFAULT 0 NOT NULL,
          tries integer DEFAULT 0 NOT NULL,
          work_done boolean DEFAULT false NOT NULL,
          class_name character varying(250) NOT NULL,
          arguments character varying NOT NULL,
          errstr character varying,
          stacktrace character varying,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE INDEX peon_jobs_work_done_idx ON peon_jobs USING btree (work_done);
    SQL
  end
end

# eof
