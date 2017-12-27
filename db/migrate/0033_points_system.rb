class PointsSystem < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE scores (
        score_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        vote_id BIGINT NOT NULL REFERENCES votes(vote_id) ON DELETE CASCADE ON UPDATE CASCADE,
        value INTEGER NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON scores (user_id, vote_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE scores;
    SQL
  end
end

# eof
