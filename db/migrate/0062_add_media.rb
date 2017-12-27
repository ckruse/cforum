class AddMedia < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE media (
        medium_id BIGSERIAL NOT NULL PRIMARY KEY,
        filename CHARACTER VARYING NOT NULL,
        orig_name CHARACTER VARYING NOT NULL,
        content_type CHARACTER VARYING NOT NULL,
        owner_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE media;
    SQL
  end
end

# eof
