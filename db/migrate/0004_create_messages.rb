class CreateMessages < ActiveRecord::Migration
  def up
    execute "DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;"

    create_table 'cforum.messages', id: false do |t|
      t.integer :thread_id, null: false, limit: 8

      t.integer :mid, limit: 8

      t.text :subject, null: false
      t.text :content, null: false

      t.text :author, null: false
      t.text :email
      t.text :homepage

      t.integer :upvotes, null: false, default: 0
      t.integer :downvotes, null: false, default: 0

      t.integer :user_id, limit: 8
      t.integer :parent_id, limit: 8

      t.boolean :deleted, default: false

      t.timestamps
    end

    execute "ALTER TABLE cforum.messages ADD COLUMN message_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.messages ADD PRIMARY KEY (message_id)"

    execute "ALTER TABLE cforum.messages ADD CONSTRAINT thread_id_fkey FOREIGN KEY (thread_id) REFERENCES cforum.threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE"
    execute "ALTER TABLE cforum.messages ADD CONSTRAINT parent_id_fkey FOREIGN KEY (parent_id) REFERENCES cforum.messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE"
    execute "ALTER TABLE cforum.messages ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE"

    add_column 'cforum.threads', :message_id, :integer
    execute "ALTER TABLE cforum.threads ADD CONSTRAINT message_id_fkey FOREIGN KEY (message_id) REFERENCES cforum.messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE"
  end

  def down
    remove_column 'cforum.threads', :message_id
    drop_table 'cforum.messages'
    execute "DO $$BEGIN DROP SCHEMA system; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema system'; END;$$;"
  end
end