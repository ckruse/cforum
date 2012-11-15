# -*- coding: utf-8 -*-

class CreateUpdateTrigger < ActiveRecord::Migration
  def up
    execute %q{
--
-- UPDATE: add one dataset with difference = +/- 1 if row is deleted/restored for each row
--
CREATE FUNCTION cforum.count_messages_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  IF OLD.deleted = false AND new.deleted = true THEN
    INSERT INTO
      cforum.counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', -1, NEW.forum_id);
  END IF;

  IF OLD.deleted = true AND new.deleted = false THEN
    INSERT INTO
      cforum.counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', +1, NEW.forum_id);
  END IF;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER messages__count_update_trigger
  AFTER UPDATE
  ON cforum.messages
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_messages_update_trigger();
    }
  end

  def down
    execute %q{
DROP TRIGGER messages__count_update_trigger ON cforum.messages;
DROP FUNCTION cforum.count_messages_update_trigger();
    }
  end
end

# eof