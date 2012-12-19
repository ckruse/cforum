--
-- INSERT: add one dataset with difference = +1 for each row
--
CREATE FUNCTION count_messages_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', +1, NEW.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER messages__count_insert_trigger
  AFTER INSERT
  ON messages
  FOR EACH ROW
  EXECUTE PROCEDURE count_messages_insert_trigger();



--
-- DELETE: add one dataset with difference = -1 for each row
--
CREATE FUNCTION count_messages_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', -1, OLD.forum_id);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER messages__count_delete_trigger
  AFTER DELETE
  ON messages
  FOR EACH ROW
  EXECUTE PROCEDURE count_messages_delete_trigger();

--
-- TRUNCATE: remove messages counting datasets and add a new one with difference = 0 for each forum
--
CREATE FUNCTION count_messages_truncate_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    counter_table
  WHERE
    table_name = 'messages';

  INSERT INTO counter_table (table_name, difference, group_crit)
    SELECT 'messages', 0, forum_id FROM forums;

  RETURN NULL;
END;
$body$;

CREATE TRIGGER messages__count_truncate_trigger
  AFTER TRUNCATE
  ON messages
  EXECUTE PROCEDURE count_messages_truncate_trigger();

--
-- INSERT forum: create a row for this forum group
--
CREATE FUNCTION count_messages_insert_forum_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  INSERT INTO
    counter_table (table_name, group_crit, difference)
    VALUES ('messages', NEW.forum_id, 0);

  RETURN NULL;
END;
$body$;

CREATE TRIGGER messages__count_insert_forum_trigger
  AFTER INSERT
  ON forums
  FOR EACH ROW
  EXECUTE PROCEDURE count_messages_insert_forum_trigger();

-- eof
