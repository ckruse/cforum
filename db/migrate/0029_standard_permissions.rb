# -*- coding: utf-8 -*-

class StandardPermissions < ActiveRecord::Migration
  def up
    execute %q{
ALTER TABLE forums DROP COLUMN public;
ALTER TABLE forums ADD COLUMN standard_permission CHARACTER VARYING(50) NOT NULL DEFAULT 'private';
    }
  end

  def down
    execute %q{
ALTER TABLE forums DROP COLUMN standard_permission;
ALTER TABLE forums ADD COLUMN public BOOLEAN NOT NULL DEFAULT false;
    }
  end
end

# eof
