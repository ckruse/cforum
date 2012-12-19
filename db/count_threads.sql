--
-- INSERT: add one dataset with difference = +1 for each row
--
CREATE FUNCTION count_threads_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, +1, NEW.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_insert_trigger
  AFTER INSERT
  ON threads
  FOR EACH ROW
  EXECUTE PROCEDURE count_threads_insert_trigger();



--
-- DELETE: add one dataset with difference = -1 for each row
--
CREATE FUNCTION count_threads_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, -1, OLD.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_delete_trigger
  AFTER DELETE
  ON threads
  FOR EACH ROW
  EXECUTE PROCEDURE count_threads_delete_trigger();

--
-- TRUNCATE: remove threads counting datasets and add a new one with difference = 0 for each forum
--
CREATE FUNCTION count_threads_truncate_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    counter_table
  WHERE
    table_name = 'threads';

  INSERT INTO counter_table (table_name, difference, group_crit)
    SELECT 'threads', 0, forum_id FROM forums;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_truncate_trigger
  AFTER TRUNCATE
  ON threads
  EXECUTE PROCEDURE count_threads_truncate_trigger();

--
-- INSERT forum: create a row for this forum group
--
CREATE FUNCTION count_threads_insert_forum_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, group_crit, difference)
    VALUES ('threads', NEW.forum_id, 0);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER threads__count_insert_forum_trigger
  AFTER INSERT
  ON forums
  FOR EACH ROW
  EXECUTE PROCEDURE count_threads_insert_forum_trigger();

-- eof
