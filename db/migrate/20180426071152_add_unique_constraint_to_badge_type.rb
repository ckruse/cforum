class AddUniqueConstraintToBadgeType < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE UNIQUE INDEX badges_badge_type_idx ON badges (badge_type) WHERE badge_type != 'custom';
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX badges_badge_type_idx;
    SQL
  end
end
