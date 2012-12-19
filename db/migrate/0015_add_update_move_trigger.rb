# -*- coding: utf-8 -*-

class AddUpdateMoveTrigger < ActiveRecord::Migration
  def up
    execute %q{
--
-- UPDATE: add one dataset with difference = +/- 1 if row is deleted/restored for each row
--
CREATE OR REPLACE FUNCTION count_messages_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
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

  IF OLD.forum_id != NEW.forum_id THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', -1, OLD.forum_id);

    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', +1, NEW.forum_id);
  END IF;

  RETURN NULL;
END;
$body$;
    }

    execute %q{
--
-- UPDATE: add one dataset with difference = +/- 1 if row is deleted/restored for each row
--
CREATE OR REPLACE FUNCTION count_threads_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  IF OLD.forum_id != NEW.forum_id THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', -1, OLD.forum_id);

    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', +1, NEW.forum_id);
  END IF;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_update_trigger
  AFTER UPDATE
  ON threads
  FOR EACH ROW
  EXECUTE PROCEDURE count_threads_update_trigger();
    }
  end

  def down
    execute "DROP TRIGGER threads__count_update_trigger ON threads;"
    execute "DROP FUNCTION count_threads_update_trigger()"
  end
end

# eof
