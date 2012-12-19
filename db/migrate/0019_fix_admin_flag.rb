# -*- coding: utf-8 -*-

class FixAdminFlag < ActiveRecord::Migration
  def up
    execute %q{
ALTER TABLE users ALTER COLUMN admin TYPE BOOLEAN USING CASE WHEN 't' THEN true ELSE false END;
    }
  end

  def down
    execute %q{
ALTER TABLE users ALTER COLUMN admin TYPE CHARACTER VARYING(255);
    }
  end
end

# eof
