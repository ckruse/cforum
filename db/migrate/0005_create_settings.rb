class CreateSettings < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.settings', id: false do |t|
      t.integer :forum_id, limit: 8
      t.integer :user_id, limit: 8

      t.string :name, null: false
      t.string :value
    end

    execute "ALTER TABLE cforum.settings ADD COLUMN setting_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.settings ADD PRIMARY KEY (setting_id)"

    execute "ALTER TABLE cforum.settings ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE"
    execute "ALTER TABLE cforum.settings ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE"
  end

  def down
    drop_table 'cforum.settings'
    execute "DO $$BEGIN DROP SCHEMA system; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema system'; END;$$;"
  end
end
