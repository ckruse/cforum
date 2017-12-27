class FixThreadLatestMessageTriggerNotSettingNull < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION messages__thread_set_latest_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id), '1970-01-01 00:00:00') WHERE thread_id = NEW.thread_id;
        RETURN NULL;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION messages__thread_set_latest_update_delete() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id), '1970-01-01 00:00:00') WHERE thread_id = OLD.thread_id;
        RETURN NULL;
      END;
      $body$;
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS messages__thread_set_latest_trigger_update ON messages;
      DROP TRIGGER IF EXISTS messages__thread_set_latest_trigger_update ON messages;
      DROP FUNCTION messages__thread_set_latest_insert();
      DROP FUNCTION messages__thread_set_latest_update_delete();
    SQL
  end
end

# eof
