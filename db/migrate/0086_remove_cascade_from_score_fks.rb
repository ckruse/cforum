class RemoveCascadeFromScoreFks < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE scores DROP CONSTRAINT scores_message_id_fkey;
      ALTER TABLE scores ADD CONSTRAINT "scores_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;

      ALTER TABLE scores DROP CONSTRAINT scores_vote_id_fkey;
      ALTER TABLE scores ADD CONSTRAINT "scores_vote_id_fkey" FOREIGN KEY (vote_id) REFERENCES votes(vote_id) ON UPDATE CASCADE ON DELETE SET NULL;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE scores DROP CONSTRAINT scores_message_id_fkey;
      ALTER TABLE scores ADD CONSTRAINT "scores_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;

      ALTER TABLE scores DROP CONSTRAINT scores_vote_id_fkey;
      ALTER TABLE scores ADD CONSTRAINT "scores_vote_id_fkey" FOREIGN KEY (vote_id) REFERENCES votes(vote_id) ON UPDATE CASCADE ON DELETE CASCADE;
    SQL
  end
end

# eof
