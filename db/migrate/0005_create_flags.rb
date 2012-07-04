class CreateFlags < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.message_flags', id: false do |t|
      t.integer :message_id, limit: 8
      t.string :flag, null: false
      t.string :value
    end

    execute "ALTER TABLE cforum.message_flags ADD COLUMN flag_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.message_flags ADD PRIMARY KEY (flag_id)"

    execute "ALTER TABLE cforum.message_flags ADD CONSTRAINT message_id_fkey FOREIGN KEY (message_id) REFERENCES cforum.messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE"
  end

  def down
    drop_table 'cforum.settings'
    execute "DO $$BEGIN DROP SCHEMA system; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema system'; END;$$;"
  end
end
