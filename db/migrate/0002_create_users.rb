class CreateUsers < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.users', id: false do |t|
      t.string :username, null: false
      t.string :email

      t.string :crypted_password
      t.string :salt

      t.timestamps

      t.timestamp :last_login_at
      t.timestamp :last_logout_at
    end

    execute "ALTER TABLE cforum.users ADD COLUMN user_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.users ADD PRIMARY KEY (user_id)"

    add_index 'cforum.users', :username, :unique => true
  end

  def down
    drop_table 'cforum.users'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end