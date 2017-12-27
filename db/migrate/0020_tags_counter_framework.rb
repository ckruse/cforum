class TagsCounterFramework < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE tags ADD COLUMN num_threads BIGINT NOT NULL DEFAULT 0;
      UPDATE tags SET num_threads = (
        SELECT
            COUNT(*)
          FROM
              tags_threads
            INNER JOIN
                threads
              USING(thread_id)
          WHERE
              tag_id = tags.tag_id
            AND
              deleted = false
      );

      CREATE OR REPLACE FUNCTION count_threads_tag_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE tags SET num_threads = num_threads + 1 WHERE tag_id = NEW.tag_id;
        RETURN NEW;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION count_threads_tag_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE tags SET num_threads = num_threads - 1 WHERE tag_id = OLD.tag_id;
        RETURN NULL;
      END;
      $body$;

      CREATE TRIGGER tags_threads__count_insert_trigger
        AFTER INSERT
        ON tags_threads
        FOR EACH ROW
        EXECUTE PROCEDURE count_threads_tag_insert_trigger();

      CREATE TRIGGER tags_threads__count_delete_trigger
        AFTER DELETE
        ON tags_threads
        FOR EACH ROW
        EXECUTE PROCEDURE count_threads_tag_delete_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER tags_threads__count_insert_trigger ON tags_threads;
      DROP TRIGGER tags_threads__count_delete_trigger ON tags_threads;
      DROP FUNCTION count_threads_tag_insert_trigger();
      DROP FUNCTION count_threads_tag_delete_trigger();
      ALTER TABLE tags DROP COLUMN num_threads;
    SQL
  end
end

# eof
