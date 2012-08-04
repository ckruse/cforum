--
-- INSERT: add one dataset with difference = +1 for each row
--
CREATE FUNCTION cforum.count_threads_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, +1, NEW.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_insert_trigger
  AFTER INSERT
  ON cforum.threads
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_threads_insert_trigger();



--
-- DELETE: add one dataset with difference = -1 for each row
--
CREATE FUNCTION cforum.count_threads_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
DECLARE field_val_v BIGINT;
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, -1, OLD.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_delete_trigger
  AFTER DELETE
  ON cforum.threads
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_threads_delete_trigger();

--
-- TRUNCATE: remove threads counting datasets and add a new one with difference = 0 for each forum
--
CREATE FUNCTION cforum.count_threads_truncate_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
    table_name = 'threads';

  INSERT INTO cforum.counter_table (table_name, difference, group_crit)
    SELECT 'threads', 0, forum_id FROM cforum.forums;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_truncate_trigger
  AFTER TRUNCATE
  ON cforum.threads
  EXECUTE PROCEDURE cforum.count_threads_truncate_trigger();

--
-- DELETE forum: remove counting datasets for this specific forum group
--
CREATE FUNCTION cforum.count_threads_delete_forum_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
      table_name = 'threads'
    AND
      group_crit = OLD.forum_id;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_delete_forum_trigger
  AFTER DELETE
  ON cforum.forums
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_threads_delete_forum_trigger();

--
-- TRUNCATE forum: remove counting datasets for all forums
--
CREATE FUNCTION cforum.count_threads_truncate_forum_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
    table_name = 'threads';

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_truncate_forum_trigger
  AFTER TRUNCATE
  ON cforum.forums
  EXECUTE PROCEDURE cforum.count_threads_truncate_forum_trigger();

-- eof