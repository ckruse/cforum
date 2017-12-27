class AddTagsNoSuggest < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE tags ADD COLUMN suggest BOOLEAN NOT NULL DEFAULT true;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE tags DROP COLUMN suggest;
    SQL
  end
end

# eof
