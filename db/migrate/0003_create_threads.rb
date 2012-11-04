class CreateThreads < ActiveRecord::Migration
  def up
    execute %q{
      DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;

      CREATE TABLE cforum.threads (
        thread_id BIGSERIAL NOT NULL PRIMARY KEY,
        slug CHARACTER VARYING(255) NOT NULL,
        forum_id BIGINT NOT NULL REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        archived BOOLEAN NOT NULL DEFAULT false,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        tid BIGINT
      );

      CREATE UNIQUE INDEX threads_slug_idx ON cforum.threads (slug);
      CREATE INDEX threads_tid_idx ON cforum.threads (tid);
      CREATE INDEX threads_archived_idx ON cforum.threads (archived);
      CREATE INDEX threads_created_at_idx ON cforum.threads (created_at);
      CREATE INDEX threads_forum_id_idx ON cforum.threads (forum_id);
      CREATE INDEX threads_message_id_idx on cforum.threads (message_id); -- used for the FKs
    }
  end

  def down
    drop_table 'cforum.threads'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end