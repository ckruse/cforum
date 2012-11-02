class CreateUsers < ActiveRecord::Migration
  def up
    execute %q{
      DO $$BEGIN CREATE SCHEMA cforum; EXCEPTION WHEN duplicate_schema THEN RAISE NOTICE 'already exists'; END;$$;

      CREATE TABLE cforum.users (
        user_id BIGSERIAL NOT NULL PRIMARY KEY,
        username CHARACTER VARYING(255) NOT NULL,
        email CHARACTER VARYING(255),

        admin CHARACTER VARYING(255),
        active BOOLEAN NOT NULL DEFAULT true,

        crypted_password CHARACTER VARYING(255),
        salt CHARACTER VARYING(255),

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        last_login_at TIMESTAMP WITHOUT TIME ZONE,
        last_logout_at TIMESTAMP WITHOUT TIME ZONE
      );

      CREATE UNIQUE INDEX users_username_idx ON cforum.users (username);
    }
  end

  def down
    drop_table 'cforum.users'
    execute "DO $$BEGIN DROP SCHEMA cforum; EXCEPTION WHEN dependent_objects_still_exist THEN RAISE NOTICE 'not removing schema cforum'; END;$$;"
  end
end