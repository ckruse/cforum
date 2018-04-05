class UniqueCiteVote < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE UNIQUE INDEX cites_votes_cite_id_user_id_idx ON cites_votes (cite_id, user_id);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX cites_votes_cite_id_user_id_idx;
    SQL
  end
end
