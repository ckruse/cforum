class AddCaseInsensitiveIndexUsernameEmail < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP INDEX users_username_idx;
      CREATE UNIQUE INDEX users_username_idx ON users(LOWER(username));
      DROP INDEX users_email_idx;
      CREATE UNIQUE INDEX users_email_idx ON users(LOWER(email));
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX users_username_idx;
      CREATE UNIQUE INDEX users_username_idx ON users(username);
      DROP INDEX users_email_idx;
      CREATE UNIQUE INDEX users_email_idx ON users(email);
    SQL
  end
end

# eof
