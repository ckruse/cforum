class AddTagSlug < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      ALTER TABLE tags ADD COLUMN slug CHARACTER VARYING(250);
    SQL

    Tag.all.each do |t|
      t.slug = t.tag_name.parameterize
      t.save
    end

    execute <<-SQL
      ALTER TABLE tags ALTER slug SET NOT NULL;
      CREATE UNIQUE INDEX tags_forum_id_slug_idx ON tags (forum_id, slug);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX tags_forum_id_slug_idx;
      ALTER TABLE tags DROP COLUMN slug;
    SQL
  end
end

# eof
