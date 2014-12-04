# -*- coding: utf-8 -*-

class AddForumKeywords < ActiveRecord::Migration
  def change
    change_table(:forums) do |t|
      t.string :keywords
    end
  end
end

# eof
