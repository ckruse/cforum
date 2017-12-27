class CacheUserScore < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE users ADD COLUMN score INT NOT NULL DEFAULT 0;
      UPDATE users SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = users.user_id), 0);

      CREATE OR REPLACE FUNCTION cache_user_score_insert_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE users
          SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = NEW.user_id), 0)
          WHERE user_id = NEW.user_id;

        RETURN NEW;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION cache_user_score_delete_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE users
          SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = OLD.user_id), 0)
          WHERE user_id = OLD.user_id;

        RETURN NEW;
      END;
      $body$;

      CREATE OR REPLACE FUNCTION cache_user_score_update_trigger() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        UPDATE users
          SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = NEW.user_id), 0)
          WHERE user_id = NEW.user_id;

        IF NEW.user_id != OLD.user_id THEN
          UPDATE users
            SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = OLD.user_id), 0)
            WHERE user_id = OLD.user_id;
        END IF;

        RETURN NEW;
      END;
      $body$;

      CREATE TRIGGER scores__cache_scores_insert_trg
        AFTER INSERT
        ON scores
        FOR EACH ROW
        EXECUTE PROCEDURE cache_user_score_insert_trigger();

      CREATE TRIGGER scores__cache_scores_delete_trg
        AFTER DELETE
        ON scores
        FOR EACH ROW
        EXECUTE PROCEDURE cache_user_score_delete_trigger();

      CREATE TRIGGER scores__cache_scores_update_trg
        AFTER UPDATE
        ON scores
        FOR EACH ROW
        EXECUTE PROCEDURE cache_user_score_update_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS scores__cache_scores_insert_trg ON scores;
      DROP TRIGGER IF EXISTS scores__cache_scores_delete_trg ON scores;
      DROP TRIGGER IF EXISTS scores__cache_scores_update_trg ON scores;
      DROP FUNCTION cache_user_score_insert_trigger();
      DROP FUNCTION cache_user_score_delete_trigger();
      DROP FUNCTION cache_user_score_update_trigger();
      ALTER TABLE users DROP COLUMN score;
    SQL
  end
end

# eof
