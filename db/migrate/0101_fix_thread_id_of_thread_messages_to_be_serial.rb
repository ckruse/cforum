class FixThreadIdOfThreadMessagesToBeSerial < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE priv_messages
        ALTER COLUMN thread_id SET DEFAULT nextval('priv_messages_thread_id_seq'),
        ALTER COLUMN thread_id SET NOT NULL;

      ALTER SEQUENCE priv_messages_thread_id_seq OWNED BY priv_messages.thread_id;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE priv_messages
        ALTER COLUMN thread_id DROP DEFAULT,
        ALTER COLUMN thread_id DROP NOT NULL;

      ALTER SEQUENCE priv_messages_thread_id_seq OWNED BY NONE;
    SQL
  end
end

# eof
