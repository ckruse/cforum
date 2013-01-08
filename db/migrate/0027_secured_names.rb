# -*- coding: utf-8 -*-

class SecuredNames < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE secured_names (
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE PRIMARY KEY,
  name CHARACTER VARYING NOT NULL
);

CREATE UNIQUE INDEX secured_names_lower_name_idx ON secured_names (LOWER(name));
    }
  end

  def down
    drop_table 'secured_names'
  end
end

# eof
