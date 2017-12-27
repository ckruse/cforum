class CreateCites < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE cites (
        cite_id BIGSERIAL PRIMARY KEY,
        old_id INTEGER UNIQUE,

        user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        message_id INTEGER REFERENCES messages(message_id) ON DELETE SET NULL ON UPDATE CASCADE,

        url TEXT NOT NULL,

        author TEXT NOT NULL,
        creator TEXT,
        cite TEXT NOT NULL,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE cites;
    SQL
  end
end

# eof
