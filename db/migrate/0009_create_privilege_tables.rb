class CreatePrivilegeTables < ActiveRecord::Migration
  def up
    add_column 'cforum.users', :admin, :string
    add_column 'cforum.users', :active, :boolean

    add_column 'cforum.forums', :public, :boolean

    create_table 'cforum.moderators', id: false do |t|
      t.integer :user_id, limit: 8
      t.integer :forum_id, limit: 8
    end

    execute "ALTER TABLE cforum.moderators ADD COLUMN moderator_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.moderators ADD PRIMARY KEY (moderator_id)"

    execute "ALTER TABLE cforum.moderators ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE"
    execute "ALTER TABLE cforum.moderators ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE"

    create_table 'cforum.access', id: false do |t|
      t.integer :user_id, limit: 8
      t.integer :forum_id, limit: 8
    end

    execute "ALTER TABLE cforum.access ADD COLUMN access_id BIGSERIAL NOT NULL"
    execute "ALTER TABLE cforum.access ADD PRIMARY KEY (access_id)"

    execute "ALTER TABLE cforum.access ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE"
    execute "ALTER TABLE cforum.access ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE"
  end

  def down
    remove_column 'cforum.users', :admin
    remove_column 'cforum.users', :active

    remove_column 'cforum.forums', :public

    drop_table 'cforum.access'
    drop_table 'cforum.moderators'
  end
end

# eof