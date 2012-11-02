class CreatePrivilegeTables < ActiveRecord::Migration
  def up
    execute %q{
      CREATE TABLE cforum.moderators (
        moderator_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES cforum.users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES cforum.forums (forum_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE TABLE cforum.access (
        access_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES cforum.users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES cforum.forums (forum_id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    }
  end

  def down
    drop_table 'cforum.access'
    drop_table 'cforum.moderators'
  end
end

# eof