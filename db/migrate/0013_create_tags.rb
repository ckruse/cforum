class CreateTags < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE tags (
        tag_id BIGSERIAL NOT NULL PRIMARY KEY,
        tag_name CHARACTER VARYING(250) NOT NULL
      );

      CREATE UNIQUE INDEX tags_tag_name_idx ON tags (tag_name);

      CREATE TABLE tags_threads (
        tag_thread_id BIGSERIAL NOT NULL,
        tag_id BIGINT NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE ON UPDATE CASCADE,
        thread_id BIGINT NOT NULL REFERENCES threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    SQL
  end

  def down
    drop_table 'tags'
  end
end

# eof
