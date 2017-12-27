class AddSettingsUserIdForumIdCheck < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION settings_unique_check() RETURNS trigger AS $body$
      BEGIN
        IF NEW.user_id IS NOT NULL AND NEW.forum_id IS NULL THEN
          IF NEW.user_id IN (
              SELECT user_id FROM settings WHERE user_id = NEW.user_id AND forum_id IS NULL
            ) THEN
            RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
          END IF;
        END IF;

        IF NEW.user_id IS NULL AND NEW.forum_id IS NOT NULL THEN
          IF NEW.forum_id IN (
              SELECT forum_id FROM settings WHERE forum_id = NEW.forum_id AND user_id IS NULL
            ) THEN
            RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
          END IF;
        END IF;

        RETURN NEW;
      END;
      $body$ LANGUAGE plpgsql;

      CREATE TRIGGER settings_unique_check BEFORE INSERT OR UPDATE ON settings
        FOR EACH ROW EXECUTE PROCEDURE settings_unique_check();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER settings_unique_check ON settings;
      DROP FUNCTION settings_unique_check();
    SQL
  end
end

# eof
