class CreateThreads < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.threads', id: false do |t|
      t.string :slug, :null => false
      t.integer :forum_id, null: false, limit: 8

      t.integer :tid, limit: 8

      t.boolean :archived, null: false, default: false

      t.timestamps
    end

    execute "ALTER TABLE cforum.threads ADD COLUMN thread_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.threads ADD PRIMARY KEY (thread_id)"

    add_index 'cforum.threads', :slug, :unique => true
  end

  def down
    drop_table 'cforum.threads'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end