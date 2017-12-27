class AddSubscriptions < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE subscriptions (
        subscription_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        message_id INT REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        UNIQUE(message_id, user_id)
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE subscriptions;
    SQL
  end
end
