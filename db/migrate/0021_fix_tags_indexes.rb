# -*- coding: utf-8 -*-

class FixTagsIndexes < ActiveRecord::Migration
  def up
    execute %q{
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
    }
  end

  def down
    execute %q{
DROP INDEX tags_forum_id_tag_name_idx;
DROP INDEX tags_threads_tag_id_idx;
DROP INDEX tags_threads_thread_id_idx;

CREATE UNIQUE INDEX tags_forum_id_tag_name_idx
  ON tags
  USING btree
  (forum_id, tag_name COLLATE pg_catalog."default");
    }
  end
end

# eof
