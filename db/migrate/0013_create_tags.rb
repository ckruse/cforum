# -*- coding: utf-8 -*-

class CreateTags < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE cforum.tags (
  tag_id BIGSERIAL NOT NULL PRIMARY KEY,
  tag_name CHARACTER VARYING(250) NOT NULL
);

CREATE UNIQUE INDEX tags_tag_name_idx ON cforum.tags (tag_name);

CREATE TABLE cforum.tags_threads (
  tag_thread_id BIGSERIAL NOT NULL,
  tag_id BIGINT NOT NULL REFERENCES cforum.tags(tag_id) ON DELETE CASCADE ON UPDATE CASCADE,
  thread_id BIGINT NOT NULL REFERENCES cforum.threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE
);
    }
  end

  def down
    drop_table 'cforum.tags'
  end
end

# eof