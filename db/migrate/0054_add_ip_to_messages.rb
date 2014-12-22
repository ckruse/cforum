# -*- coding: utf-8 -*-

class AddIpToMessages < ActiveRecord::Migration
  def change
    change_table(:messages) do |t|
      t.string :ip
    end
  end
end

# eof
