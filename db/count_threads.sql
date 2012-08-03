CREATE TABLE cforum.counter_table (
  count_id BIGSERIAL NOT NULL PRIMARY KEY,
  table_name NAME NOT NULL,
  group_crit BIGINT,
  difference BIGINT NOT NULL
);

CREATE INDEX ON cforum.counter_table (table_name, group_crit);

CREATE FUNCTION cforum.counter_table__insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
DECLARE field_val_v BIGINT;
BEGIN
  EXECUTE 'SELECT (' || quote_literal(NEW) || '::' || TG_RELID::regclass || ').' || quote_ident(TG_ARGV[0]) INTO field_val_v;

  IF field_val_v = TG_ARGV[1]::bigint THEN
    INSERT INTO
      cforum.counter_table (table_name, difference, group_crit)
    VALUES
      (TG_TABLE_NAME, +1, TG_ARGV[1]::bigint);
  END IF;

  RETURN NULL;
END;
$body$;

CREATE FUNCTION cforum.counter_table__delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
DECLARE field_val_v BIGINT;
BEGIN
  RAISE NOTICE 'col: %, val: %', TG_ARGV[0], TG_ARGV[1];

  EXECUTE 'SELECT (' || quote_literal(OLD) || '::' || TG_RELID::regclass || ').' || quote_ident(TG_ARGV[0]) INTO field_val_v;

  IF field_val_v = TG_ARGV[1]::bigint THEN
    INSERT INTO
      cforum.counter_table (table_name, difference, group_crit)
    VALUES
      (TG_TABLE_NAME, -1, TG_ARGV[1]::bigint);
  END IF;

  RETURN NULL;
END;
$body$;

CREATE FUNCTION cforum.counter_table__truncate_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
    table_name = TG_TABLE_NAME AND (TG_ARGV[0] IS NULL OR group_crit = TG_ARGV[0]::bigint);

  INSERT INTO
    cforum.counter_table(table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, 0, TG_ARGV[0]::bigint);

  RETURN NULL;
END;
$body$;


CREATE OR REPLACE FUNCTION cforum.counter_table_get_count(v_table_name NAME, v_group_crit BIGINT) RETURNS BIGINT LANGUAGE plpgsql AS $body$
DECLARE
  v_table_n NAME := quote_ident(v_table_name);
  v_sum BIGINT;
  v_nr BIGINT;
BEGIN
  SELECT
    COUNT(*), SUM(difference)
  FROM
    cforum.counter_table
  WHERE
      table_name = v_table_name
    AND
      (v_group_crit IS NULL OR group_crit = v_group_crit)
  INTO v_nr, v_sum;

  IF v_sum IS NULL THEN
    RAISE EXCEPTION 'table_count: count on uncounted table';
  END IF;

  /*
   * We only sum up if we encounter a big enough amount of rows so summing
   * is a real benefit.
   */
  IF v_nr > 100 THEN
    DECLARE
      v_cur_id BIGINT;
      v_cur_difference BIGINT;
      v_new_sum BIGINT := 0;
      v_delete_ids BIGINT[];

    BEGIN
      RAISE NOTICE 'table_count: summing counter';

      FOR v_cur_id, v_cur_difference IN
        SELECT
          id, difference
          FROM
            cforum.counter_table
          WHERE
              table_name = v_table_name
            AND
              (v_group_crit IS NULL OR group_crit = v_group_crit)
          ORDER BY
            count_id
          FOR UPDATE NOWAIT
      LOOP
        --collecting ids instead of doing every single delete is more efficient
        v_delete_ids := v_delete_ids || v_cur_id;
        v_new_sum := v_new_sum + v_cur_difference;

        IF array_length(v_delete_ids, 1) > 100 THEN
          DELETE FROM cforum.counter_table WHERE id = ANY(v_delete_ids);
          v_delete_ids = '{}';
        END IF;

      END LOOP;

      DELETE FROM cforum.counter_table WHERE id = ANY(v_delete_ids);
      INSERT INTO cforum.counter_table(table_name, group_crit, difference) VALUES(v_table_name, v_group_crit, v_new_sum);

    EXCEPTION
      --if somebody else summed up in a transaction which was open at the
      --same time we ran the above statement
      WHEN lock_not_available THEN
        RAISE NOTICE 'table_count: locking failed';
      --if somebody else summed up in a transaction which has committed
      --successfully
      WHEN serialization_failure THEN
        RAISE NOTICE 'table_count: serialization failed';
      --summing up won't work in a readonly transaction. One could check
      --that explicitly
      WHEN read_only_sql_transaction THEN
        RAISE NOTICE 'table_count: not summing because in read only txn';
    END;
  END IF;

  RETURN v_sum;
END;
$body$;

CREATE FUNCTION cforum.counter_table_create_count_trigger(v_table_name name, v_crit_column name, v_group_crit BIGINT) RETURNS void LANGUAGE plpgsql VOLATILE AS $body$
DECLARE
  v_table_n name := quote_ident(v_table_name);
  v_crit_column_n name := quote_ident(v_crit_column);
BEGIN
  EXECUTE
    'CREATE TRIGGER "' || v_table_n || '__count_insert__' || v_crit_column || '"
      AFTER INSERT
      ON ' || v_table_n || '
      FOR EACH ROW
      EXECUTE PROCEDURE cforum.counter_table__insert_trigger(''' || v_crit_column || ''', ' || v_group_crit ||')';

  EXECUTE
    'CREATE TRIGGER "' || v_table_n || '__count_delete__' || v_crit_column || '"
      AFTER DELETE
      ON ' || v_table_n || '
      FOR EACH ROW
      EXECUTE PROCEDURE cforum.counter_table__delete_trigger(''' || v_crit_column || ''', ' || v_group_crit ||')';

  EXECUTE
    'CREATE TRIGGER "' || v_table_n || '__count_truncate__' || v_crit_column || '"
      AFTER TRUNCATE
      ON ' || v_table_n || '
      FOR EACH STATEMENT
      EXECUTE PROCEDURE cforum.counter_table__truncate_trigger(''' || v_crit_column || ''', ' || v_group_crit ||')';

  /*
   * If the function was dropped without cleaning the content for that table
   * we would end up with old content + a new count
   */
  DELETE FROM cforum.counter_table WHERE table_name = v_table_name AND (v_group_crit IS NULL OR v_group_crit = group_crit);
  EXECUTE
    'INSERT INTO cforum.counter_table(table_name, difference, group_crit)
        SELECT $1, COUNT(*), $2 FROM ' || v_table_n || ' WHERE $2 IS NULL OR $2 = ' || v_crit_column_n USING v_table_name, v_group_crit;
END
$body$;


CREATE FUNCTION cforum.counter_table_remove_count_trigger(v_table_name name, v_crit_column name, v_group_crit BIGINT) RETURNS void LANGUAGE plpgsql VOLATILE AS $body$
DECLARE
  v_table_n name := quote_ident(v_table_name);
  v_crit_column_n name := quote_ident(v_crit_column);
BEGIN
  EXECUTE 'DROP TRIGGER IF EXISTS ' || v_table_n || '__count_insert__' || v_crit_column || ' ON ' || v_table_n;
  EXECUTE 'DROP TRIGGER IF EXISTS ' || v_table_n || '__count_delete__' || v_crit_column || ' ON ' || v_table_n;
  EXECUTE 'DROP TRIGGER IF EXISTS ' || v_table_n || '__count_truncate__' || v_crit_column || ' ON ' || v_table_n;

  DELETE FROM cforum.counter_table WHERE table_name = v_table_name AND (v_group_crit IS NULL OR group_crit = v_group_crit);
END
$body$;

