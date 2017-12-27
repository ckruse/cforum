class CreateUsers < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TABLE users (
        user_id BIGSERIAL NOT NULL PRIMARY KEY,
        username CHARACTER VARYING(255) NOT NULL,
        email CHARACTER VARYING(255),
        unconfirmed_email CHARACTER VARYING(255),

        admin CHARACTER VARYING(255),
        active BOOLEAN NOT NULL DEFAULT true,

        encrypted_password CHARACTER VARYING(255) NOT NULL DEFAULT '',

        remember_created_at TIMESTAMP WITHOUT TIME ZONE,

        reset_password_token CHARACTER VARYING(255),
        reset_password_sent_at TIMESTAMP WITHOUT TIME ZONE,

        confirmation_token CHARACTER VARYING(255),
        confirmed_at TIMESTAMP WITHOUT TIME ZONE,
        confirmation_sent_at TIMESTAMP WITHOUT TIME ZONE,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        authentication_token CHARACTER VARYING(255)
      );

      CREATE UNIQUE INDEX users_username_idx ON users (username);
      CREATE UNIQUE INDEX users_email_idx ON users (email);
      CREATE UNIQUE INDEX users_reset_password_token_idx ON users (reset_password_token);
      CREATE UNIQUE INDEX users_confirmation_token_idx ON users (confirmation_token);
      CREATE UNIQUE INDEX users_authentication_token_idx ON users (authentication_token);
    SQL
  end

  def down
    drop_table 'users'
  end
end
