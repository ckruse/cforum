# -*- coding: utf-8 -*-

class AddTagSlug < ActiveRecord::Migration
  def up
    execute "ALTER TABLE cforum.tags ADD COLUMN slug CHARACTER VARYING(250);";

    CfTag.all.each do |t|
      t.slug = t.tag_name.parameterize
      t.save
    end

    execute "ALTER TABLE cforum.tags ALTER slug SET NOT NULL;"
    execute "CREATE UNIQUE INDEX tags_forum_id_slug_idx ON cforum.tags (forum_id, slug);"
  end

  def down
    execute %q{
DROP INDEX cforum.tags_forum_id_slug_idx;
ALTER TABLE cforum.tags DROP COLUMN slug;
    }
  end
end

# eof
