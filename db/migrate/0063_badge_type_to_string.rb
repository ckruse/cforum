class BadgeTypeToString < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE badges ADD COLUMN badge_type_new CHARACTER VARYING(250);
      UPDATE badges SET badge_type_new = badge_type;
      ALTER TABLE badges DROP COLUMN badge_type;
      ALTER TABLE badges RENAME badge_type_new TO badge_type;
      ALTER TABLE badges ALTER COLUMN badge_type SET NOT NULL;
      DROP TYPE badge_type_t;
      DELETE FROM badges WHERE badge_type = 'flag';
    SQL
  end
end

# eof
