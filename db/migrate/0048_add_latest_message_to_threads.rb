class AddLatestMessageToThreads < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE threads ADD COLUMN latest_message TIMESTAMP WITHOUT TIME ZONE;

      CREATE OR REPLACE FUNCTION messages__thread_set_latest() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE threads SET latest_message = (SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id) WHERE thread_id = OLD.thread_id;
        RETURN NULL;
      END;
      $body$;

      CREATE TRIGGER messages__thread_set_latest_trigger
        AFTER UPDATE OR INSERT OR DELETE
        ON messages
        FOR EACH ROW
        EXECUTE PROCEDURE messages__thread_set_latest();

      UPDATE threads SET latest_message = (SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id);
      ALTER TABLE threads ALTER COLUMN latest_message SET NOT NULL;

    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER messages__thread_set_latest_trigger;
      DROP FUNCTION messages__thread_set_latest();
    SQL
  end
end

# eof
