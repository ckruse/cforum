class AddCelebrationBadges < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    ALTER TABLE badges
      ALTER COLUMN score_needed DROP NOT NULL;
    SQL
  end

  def down
    execute <<-SQL
    ALTER TABLE badges
      ALTER COLUMN score_needed SET NOT NULL;
    SQL
  end
end

# eof
