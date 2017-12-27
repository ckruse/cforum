class AddCloseVotes < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE close_votes (
        close_vote_id BIGSERIAL PRIMARY KEY,
        message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
        reason VARCHAR(20) NOT NULL,
        duplicate_slug VARCHAR(255),
        custom_reason VARCHAR(255),

        finished BOOLEAN NOT NULL DEFAULT false,

        vote_type BOOLEAN NOT NULL DEFAULT false,

        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL,

        UNIQUE(message_id, vote_type)
      );

      CREATE TABLE close_votes_voters (
        close_votes_voter_id BIGSERIAL PRIMARY KEY,
        close_vote_id BIGINT NOT NULL REFERENCES close_votes(close_vote_id) ON DELETE CASCADE ON UPDATE CASCADE,

        user_id BIGINT NOT NULL,

        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL,

        UNIQUE(close_vote_id, user_id)
      );
    SQL
  end

  def down
    drop_table 'close_votes_voters'
    drop_table 'close_votes'
  end
end

# eof
