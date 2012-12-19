class CreateSettings < ActiveRecord::Migration
  def up
    execute %q{
      DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;

      CREATE TABLE settings (
        setting_id BIGSERIAL NOT NULL PRIMARY KEY,
        forum_id BIGINT REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        options HSTORE
      );

      CREATE INDEX settings_forum_id_idx ON settings (forum_id);
      CREATE INDEX settings_user_id_idx ON settings (user_id);

      -- constraint to ensure that there is only one user settings object per user and forum
      CREATE UNIQUE INDEX settings_forum_id_user_id_idx ON settings (forum_id, user_id);
    }
  end

  def down
    drop_table 'settings'
    execute "DO $$BEGIN DROP SCHEMA system; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema system'; END;$$;"
  end
end
