class AddVotingToCites < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE cites ADD COLUMN cite_date TIMESTAMP WITHOUT TIME ZONE;
      UPDATE cites SET cite_date = created_at;
      ALTER TABLE cites ALTER COLUMN cite_date SET NOT NULL;
      ALTER TABLE cites ADD COLUMN archived BOOLEAN NOT NULL DEFAULT true;
      ALTER TABLE cites ALTER COLUMN archived SET DEFAULT false;

      ALTER TABLE cites ADD COLUMN creator_user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE;

      CREATE TABLE cites_votes (
        cite_vote_id BIGSERIAL PRIMARY KEY,
        cite_id BIGINT NOT NULL REFERENCES cites(cite_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        vote_type INT,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE cites DROP COLUMN creator_user_id;
      ALTER TABLE cites DROP COLUMN cite_date;
      ALTER TABLE cites DROP COLUMN archived;

      DROP TABLE cites_votes;
    SQL
  end
end

# eof
