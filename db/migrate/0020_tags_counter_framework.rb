# -*- coding: utf-8 -*-

class TagsCounterFramework < ActiveRecord::Migration
  def up
    execute %q{
ALTER TABLE cforum.tags ADD COLUMN num_threads BIGINT NOT NULL DEFAULT 0;
UPDATE cforum.tags SET num_threads = (
  SELECT
      COUNT(*)
    FROM
        cforum.tags_threads
      INNER JOIN
          cforum.threads
        USING(thread_id)
    WHERE
        tag_id = tags.tag_id
      AND
        deleted = false
);

CREATE OR REPLACE FUNCTION cforum.count_threads_tag_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  UPDATE cforum.tags SET num_threads = num_threads + 1 WHERE tag_id = NEW.tag_id;
  RETURN NEW;
END;
$body$;

CREATE OR REPLACE FUNCTION cforum.count_threads_tag_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
  UPDATE cforum.tags SET num_threads = num_threads - 1 WHERE tag_id = OLD.tag_id;
  RETURN NULL;
END;
$body$;

CREATE TRIGGER tags_threads__count_insert_trigger
  AFTER INSERT
  ON cforum.tags_threads
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_threads_tag_insert_trigger();

CREATE TRIGGER tags_threads__count_delete_trigger
  AFTER DELETE
  ON cforum.tags_threads
  FOR EACH ROW
  EXECUTE PROCEDURE cforum.count_threads_tag_delete_trigger();
    }
  end

  def down
    execute %q{
DROP TRIGGER tags_threads__count_insert_trigger ON cforum.tags_threads;
DROP TRIGGER tags_threads__count_delete_trigger ON cforum.tags_threads;
DROP FUNCTION cforum.count_threads_tag_insert_trigger();
DROP FUNCTION cforum.count_threads_tag_delete_trigger();
ALTER TABLE cforum.tags DROP COLUMN num_threads;
    }
  end
end

# eof
