class CreateSettings < ActiveRecord::Migration
  def up
    execute %q{
      DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;

      CREATE TABLE cforum.settings (
        setting_id BIGSERIAL NOT NULL PRIMARY KEY,
        forum_id BIGINT REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        options HSTORE
      );

      CREATE INDEX settings_forum_id_idx ON cforum.settings (forum_id);
      CREATE INDEX settings_user_id_idx ON cforum.settings (user_id);
    }
  end

  def down
    drop_table 'cforum.settings'
    execute "DO $$BEGIN DROP SCHEMA system; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema system'; END;$$;"
  end
end
