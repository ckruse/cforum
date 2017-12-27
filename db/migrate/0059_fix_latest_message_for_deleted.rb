class FixLatestMessageForDeleted < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION messages__thread_set_latest_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id AND deleted = false), '1970-01-01 00:00:00') WHERE thread_id = NEW.thread_id;
        RETURN NULL;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION messages__thread_set_latest_update_delete() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id AND deleted = false), '1970-01-01 00:00:00') WHERE thread_id = OLD.thread_id;
        RETURN NULL;
      END;
      $body$;

      UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id AND deleted = false), '1970-01-01 00:00:00');
    SQL
  end

  def down; end
end

# eof
