class CreatePrivilegeTables < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TABLE forum_permissions (
        forum_permission_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES forums (forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        permission CHARACTER VARYING(255) NOT NULL DEFAULT 'read'
      );

      CREATE INDEX forum_permissions_user_id_idx ON forum_permissions (user_id);
      CREATE INDEX forum_permissions_forum_id_idx ON forum_permissions (user_id);
      CREATE UNIQUE INDEX forum_permissions_user_id_forum_id_permission_idx ON forum_permissions (user_id, forum_id, permission);
    SQL
  end

  def down
    drop_table 'forum_permissions'
    drop_table 'moderators'
  end
end

# eof
