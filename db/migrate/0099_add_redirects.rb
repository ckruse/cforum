class AddRedirects < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE redirections (
        redirection_id BIGSERIAL PRIMARY KEY,
        path CHARACTER VARYING NOT NULL UNIQUE,
        destination CHARACTER VARYING NOT NULL,
        http_status INT NOT NULL,
        comment TEXT
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE redirections;
    SQL
  end
end
