class CreateThreads < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TABLE threads (
        thread_id BIGSERIAL NOT NULL PRIMARY KEY,
        slug CHARACTER VARYING(255) NOT NULL,
        forum_id BIGINT NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        archived BOOLEAN NOT NULL DEFAULT false,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        tid BIGINT
      );

      CREATE UNIQUE INDEX threads_slug_idx ON threads (slug);
      CREATE INDEX threads_tid_idx ON threads (tid);
      CREATE INDEX threads_archived_idx ON threads (archived);
      CREATE INDEX threads_created_at_idx ON threads (created_at);
      CREATE INDEX threads_forum_id_idx ON threads (forum_id);
    SQL
  end

  def down
    drop_table 'threads'
  end
end
