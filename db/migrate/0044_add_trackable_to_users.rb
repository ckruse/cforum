class AddTrackableToUsers < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE users ADD COLUMN last_sign_in_at TIMESTAMP WITHOUT TIME ZONE;
      ALTER TABLE users ADD COLUMN current_sign_in_at TIMESTAMP WITHOUT TIME ZONE;
      ALTER TABLE users ADD COLUMN last_sign_in_ip CHARACTER VARYING;
      ALTER TABLE users ADD COLUMN current_sign_in_ip CHARACTER VARYING;
      ALTER TABLE users ADD COLUMN sign_in_count INT;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE users DROP COLUMN last_sign_in_at;
      ALTER TABLE users DROP COLUMN current_sign_in_at;
      ALTER TABLE users DROP COLUMN last_sign_in_ip;
      ALTER TABLE users DROP COLUMN current_sign_in_ip;
      ALTER TABLE users DROP COLUMN sign_in_count;
    SQL
  end
end

# eof
