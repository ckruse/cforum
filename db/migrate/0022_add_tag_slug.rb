# -*- coding: utf-8 -*-

class AddTagSlug < ActiveRecord::Migration
  def up
    execute "ALTER TABLE tags ADD COLUMN slug CHARACTER VARYING(250);";

    CfTag.all.each do |t|
      t.slug = t.tag_name.parameterize
      t.save
    end

    execute "ALTER TABLE tags ALTER slug SET NOT NULL;"
    execute "CREATE UNIQUE INDEX tags_forum_id_slug_idx ON tags (forum_id, slug);"
  end

  def down
    execute %q{
DROP INDEX tags_forum_id_slug_idx;
ALTER TABLE tags DROP COLUMN slug;
    }
  end
end

# eof
