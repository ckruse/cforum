class CreateForums < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.forums', id: false do |t|
      t.string :slug, :null => false

      t.string :name
      t.string :short_name

      t.text :description

      t.timestamps
    end

    execute "ALTER TABLE cforum.forums ADD COLUMN forum_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.forums ADD PRIMARY KEY (forum_id)"

    add_index 'cforum.forums', :slug, :unique => true
  end

  def down
    drop_table 'cforum.forums'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end