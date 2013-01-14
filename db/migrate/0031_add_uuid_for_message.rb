# -*- coding: utf-8 -*-

class AddUuidForMessage < ActiveRecord::Migration
  def up
    execute "ALTER TABLE messages ADD COLUMN uuid CHARACTER VARYING(250);"
  end

  def down
    execute "ALTER TABLE messages DROP COLUMN uuid"
  end
end

# eof
