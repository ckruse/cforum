class AddTwitterAuthorizations < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE twitter_authorizations (
        twitter_authorization_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,
        token TEXT NOT NULL,
        secret TEXT NOT NULL
      )
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE twitter_authorizations;
    SQL
  end
end
