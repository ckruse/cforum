# -*- coding: utf-8 -*-

class AddFlagsForThread < ActiveRecord::Migration
  def up
    execute <<-SQL
ALTER TABLE threads ADD COLUMN flags hstore;
    SQL
  end

  def down
    execute <<-SQL
ALTER TABLE threads DROP COLUMN flags;
    SQL
  end
end

# eof
