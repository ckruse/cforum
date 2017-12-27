class AddGroupsToBadges < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE badge_groups (
        badge_group_id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE UNIQUE INDEX ON badge_groups (LOWER(name));

      CREATE TABLE badges_badge_groups (
        badges_badge_group_id SERIAL PRIMARY KEY,
        badge_group_id INTEGER NOT NULL REFERENCES badge_groups(badge_group_id) ON DELETE CASCADE ON UPDATE CASCADE,
        badge_id INTEGER NOT NULL REFERENCES badges(badge_id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE badges_badge_groups;
      DROP TABLE badge_groups;
    SQL
  end
end

# eof
