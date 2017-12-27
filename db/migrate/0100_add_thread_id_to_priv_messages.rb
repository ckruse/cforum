class AddThreadIdToPrivMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE priv_messages
        ADD COLUMN thread_id BIGINT;

      CREATE SEQUENCE priv_messages_thread_id_seq;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE priv_messages
        DROP COLUMN thread_id;

      DROP SEQUENCE priv_messages_thread_id_seq;
    SQL
  end
end

# eof
