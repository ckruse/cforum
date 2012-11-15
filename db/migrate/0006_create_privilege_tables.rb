class CreatePrivilegeTables < ActiveRecord::Migration
  def up
    execute %q{
      CREATE TABLE cforum.forum_permissions (
        forum_permission_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES cforum.users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES cforum.forums (forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        permission CHARACTER VARYING(255) NOT NULL DEFAULT 'read'
      );

      CREATE INDEX forum_permissions_user_id_idx ON cforum.forum_permissions (user_id);
      CREATE INDEX forum_permissions_forum_id_idx ON cforum.forum_permissions (user_id);
      CREATE UNIQUE INDEX forum_permissions_user_id_forum_id_permission_idx ON cforum.forum_permissions (user_id, forum_id, permission);
    }
  end

  def down
    drop_table 'cforum.forum_permissions'
    drop_table 'cforum.moderators'
  end
end

# eof