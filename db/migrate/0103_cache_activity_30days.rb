class CacheActivity30days < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE users ADD COLUMN activity INT NOT NULL DEFAULT 0;
      UPDATE users
        SET activity = COALESCE((SELECT COUNT(*)
                                 FROM messages
                                 WHERE messages.user_id = users.user_id AND
                                   created_at >= NOW() - INTERVAL '30 days' AND deleted = false), 0);

      CREATE OR REPLACE FUNCTION cache_user_activity_insert_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        IF NEW.user_id IS NULL THEN
          RETURN NEW;
        END IF;

        UPDATE users
          SET activity = COALESCE((SELECT COUNT(*)
                                   FROM messages
                                   WHERE messages.user_id = NEW.user_id AND created_at >= NOW() - INTERVAL '30 days' AND deleted = false), 0)
          WHERE user_id = NEW.user_id;

        RETURN NEW;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION cache_user_activity_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        IF OLD.user_id IS NULL THEN
          RETURN OLD;
        END IF;

        UPDATE users
          SET activity = COALESCE((SELECT COUNT(*)
                                   FROM messages
                                   WHERE messages.user_id = OLD.user_id AND created_at >= NOW() - INTERVAL '30 days' AND deleted = false), 0)
          WHERE user_id = OLD.user_id;

        RETURN OLD;
      END;
      $body$;

      CREATE TRIGGER messages__cache_activity_insert_update_trg
        AFTER INSERT OR UPDATE
        ON messages
        FOR EACH ROW
        EXECUTE PROCEDURE cache_user_activity_insert_update_trigger();

      CREATE TRIGGER messages__cache_activity_delete_trg
        AFTER DELETE
        ON messages
        FOR EACH ROW
        EXECUTE PROCEDURE cache_user_activity_delete_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS messages__cache_activity_insert_update_trg ON messages;
      DROP TRIGGER IF EXISTS messages__cache_activity_delete_trg ON messages;
      DROP FUNCTION cache_user_activity_insert_update_trigger();
      DROP FUNCTION cache_user_activity_delete_trigger();
      ALTER TABLE users DROP COLUMN activity;
    SQL
  end
end

# eof
