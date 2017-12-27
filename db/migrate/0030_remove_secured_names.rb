class RemoveSecuredNames < ActiveRecord::Migration[5.0]
  def up
    drop_table 'secured_names'
  end

  def down
    execute <<~SQL
      CREATE TABLE secured_names (
        user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE PRIMARY KEY,
        name CHARACTER VARYING NOT NULL
      );

      CREATE UNIQUE INDEX secured_names_lower_name_idx ON secured_names (LOWER(name));
    SQL
  end
end

# eof
