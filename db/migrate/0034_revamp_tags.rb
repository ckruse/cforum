class RevampTags < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP TABLE IF EXISTS tags_threads CASCADE;
      DROP TABLE IF EXISTS tags CASCADE;

      DROP FUNCTION IF EXISTS count_threads_tag_insert_trigger();
      DROP FUNCTION IF EXISTS count_threads_tag_delete_trigger();

      CREATE TABLE tags (
        tag_id BIGSERIAL NOT NULL PRIMARY KEY,
        tag_name CHARACTER VARYING NOT NULL,
        slug CHARACTER VARYING NOT NULL,
        forum_id BIGINT NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        num_messages BIGINT
      );

      CREATE UNIQUE INDEX tags_tag_name_forum_id_idx ON tags (tag_name, forum_id);
      CREATE INDEX tags_forum_id_idx ON tags (forum_id);

      CREATE TABLE messages_tags (
        message_tag_id BIGSERIAL NOT NULL PRIMARY KEY,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        tag_id BIGINT NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE INDEX messages_tags_message_id_idx ON messages_tags (message_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE messages_tags CASCADE;
      DROP TABLE tags CASCADE;
    SQL
  end
end

# eof
