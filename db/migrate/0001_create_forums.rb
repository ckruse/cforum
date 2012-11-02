class CreateForums < ActiveRecord::Migration
  def up
    execute %q{
      DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;

      CREATE TABLE cforum.forums (
        forum_id BIGSERIAL PRIMARY KEY NOT NULL,
        slug CHARACTER VARYING(255) NOT NULL,
        short_name CHARACTER VARYING(255) NOT NULL,

        public BOOLEAN NOT NULL DEFAULT true,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        name CHARACTER VARYING NOT NULL,
        description CHARACTER VARYING
      );

      CREATE UNIQUE INDEX forums_slug_idx ON cforum.forums (slug);
    }
  end

  def down
    drop_table 'cforum.forums'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end