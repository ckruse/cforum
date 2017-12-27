class CreateUpdateTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      --
      -- UPDATE: add one dataset with difference = +/- 1 if row is deleted/restored for each row
      --
      CREATE FUNCTION count_messages_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        IF OLD.deleted = false AND new.deleted = true THEN
          INSERT INTO
            counter_table (table_name, difference, group_crit)
          VALUES
            ('messages', -1, NEW.forum_id);
        END IF;

        IF OLD.deleted = true AND new.deleted = false THEN
          INSERT INTO
            counter_table (table_name, difference, group_crit)
          VALUES
            ('messages', +1, NEW.forum_id);
        END IF;

        RETURN NULL;
      END;
      $body$;

      CREATE TRIGGER messages__count_update_trigger
        AFTER UPDATE
        ON messages
        FOR EACH ROW
        EXECUTE PROCEDURE count_messages_update_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER messages__count_update_trigger ON messages;
      DROP FUNCTION count_messages_update_trigger();
    SQL
  end
end

# eof
