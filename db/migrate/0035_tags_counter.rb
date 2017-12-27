class TagsCounter < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE tags ALTER COLUMN num_messages SET DEFAULT 0;

      UPDATE tags SET num_messages = (
        SELECT
            COUNT(*)
          FROM
              messages_tags
            INNER JOIN
                messages
              USING(message_id)
          WHERE
              tag_id = tags.tag_id
            AND
              deleted = false
      );

      ALTER TABLE tags ALTER COLUMN num_messages SET NOT NULL;

      CREATE OR REPLACE FUNCTION count_messages_tag_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE tags SET num_messages = num_messages + 1 WHERE tag_id = NEW.tag_id;
        RETURN NEW;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION count_messages_tag_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE tags SET num_messages = num_messages - 1 WHERE tag_id = OLD.tag_id;
        RETURN NULL;
      END;
      $body$;

      CREATE TRIGGER messages_tags__count_insert_trigger
        AFTER INSERT
        ON messages_tags
        FOR EACH ROW
        EXECUTE PROCEDURE count_messages_tag_insert_trigger();

      CREATE TRIGGER messages_tags__count_delete_trigger
        AFTER DELETE
        ON messages_tags
        FOR EACH ROW
        EXECUTE PROCEDURE count_messages_tag_delete_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER messages_tags__count_insert_trigger ON messages_tags;
      DROP TRIGGER messages_tags__count_delete_trigger ON messages_tags;
      DROP FUNCTION count_messages_tag_insert_trigger();
      DROP FUNCTION count_messages_tag_delete_trigger();
      ALTER TABLE tags ALTER COLUMN num_messages SET NULL;
    SQL
  end
end

# eof
