# -*- coding: utf-8 -*-

class CreateTagSynonyms < ActiveRecord::Migration
  def up
    execute <<-SQL
CREATE TABLE tag_synonyms (
  tag_synonym_id BIGSERIAL NOT NULL PRIMARY KEY,
  tag_id BIGINT NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE ON UPDATE CASCADE,
  synonym CHARACTER VARYING(250) NOT NULL
);

CREATE INDEX tag_synonyms_tag_id_idx ON tag_synonyms (tag_id);
CREATE INDEX tag_synonyms_synonym_idx ON tag_synonyms (synonym);
CREATE UNIQUE INDEX tag_synonyms_tag_id_synonym_idx ON tag_synonyms (tag_id, synonym);
    SQL
  end

  def down
    execute <<-SQL
DROP TABLE tag_synonyms;
    SQL
  end
end

# eof
