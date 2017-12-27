class AddAuditing < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE auditing (
        auditing_id BIGSERIAL PRIMARY KEY,
        relation REGCLASS NOT NULL,
        relid BIGINT NOT NULL,
        act TEXT NOT NULL,
        contents JSON NOT NULL,
        user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE auditing;
    SQL
  end
end

# eof
