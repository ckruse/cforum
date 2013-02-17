# -*- coding: utf-8 -*-

class CreateSticky < ActiveRecord::Migration
  def up
    execute %q{
ALTER TABLE threads ADD COLUMN sticky BOOLEAN NOT NULL DEFAULT false;
    }
  end

  def down
    execute %q{
ALTER TABLE threads DROP COLUMN sticky;
    }
  end
end

# eof
