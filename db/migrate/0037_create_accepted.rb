class CreateAccepted < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN accepted BOOLEAN NOT NULL DEFAULT false;
      ALTER TABLE scores ADD COLUMN message_id BIGINT REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE;
      ALTER TABLE scores ALTER COLUMN vote_id DROP NOT NULL;

      DROP INDEX scores_user_id_vote_id_idx;
      CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON scores (user_id, vote_id) WHERE vote_id IS NOT NULL;
      CREATE UNIQUE INDEX scores_user_id_message_id_idx ON scores (user_id, message_id) WHERE message_id IS NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages DROP COLUMN accepted;
      ALTER TABLE scores DROP COLUMN message_id;
      ALTER TABLE scores ALTER COLUMN vote_id SET NOT NULL;

      DROP INDEX scores_user_id_vote_id_idx;
      DROP INDEX scores_user_id_message_id_idx;
      CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON scores (user_id, vote_id);
    SQL
  end
end

# eof
