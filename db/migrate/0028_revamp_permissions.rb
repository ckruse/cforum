class RevampPermissions < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP TABLE forum_permissions;

      CREATE TABLE groups (
        group_id BIGSERIAL NOT NULL PRIMARY KEY,
        name CHARACTER VARYING(255) NOT NULL UNIQUE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE TABLE forums_groups_permissions (
        forum_group_permission_id BIGSERIAL NOT NULL PRIMARY KEY,
        permission CHARACTER VARYING(50) NOT NULL,
        group_id BIGINT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE ON UPDATE CASCADE,
        forum_id BIGINT NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE TABLE groups_users (
        group_user_id BIGSERIAL NOT NULL PRIMARY KEY,
        group_id BIGINT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE forums_groups_permissions;
      DROP TABLE groups_users;
      DROP TABLE groups;

      CREATE TABLE forum_permissions (
        forum_permission_id bigserial NOT NULL PRIMARY KEY,
        user_id bigint NOT NULL REFERENCES users (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
        forum_id bigint NOT NULL REFERENCES forums (forum_id) ON UPDATE CASCADE ON DELETE CASCADE,
        permission character varying(255) NOT NULL DEFAULT 'read'
      );

      CREATE INDEX forum_permissions_forum_id_idx ON forum_permissions USING btree (forum_id);
      CREATE UNIQUE INDEX forum_permissions_user_id_forum_id_permission_idx ON forum_permissions USING btree (user_id, forum_id, permission);
      CREATE INDEX forum_permissions_user_id_idx ON forum_permissions USING btree (user_id);
    SQL
  end
end

# eof
