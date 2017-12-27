class FixTagsIndexes < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP INDEX tags_forum_id_tag_name_idx;
      CREATE UNIQUE INDEX tags_forum_id_tag_name_idx
        ON tags
        USING btree
        (forum_id, UPPER(tag_name));

      CREATE INDEX tags_threads_tag_id_idx
        ON tags_threads
        USING btree
        (tag_id);
      CREATE INDEX tags_threads_thread_id_idx
        ON tags_threads
        USING btree
        (thread_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX tags_forum_id_tag_name_idx;
      DROP INDEX tags_threads_tag_id_idx;
      DROP INDEX tags_threads_thread_id_idx;

      CREATE UNIQUE INDEX tags_forum_id_tag_name_idx
        ON tags
        USING btree
        (forum_id, tag_name COLLATE pg_catalog."default");
    SQL
  end
end

# eof
