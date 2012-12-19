# -*- encoding: utf-8 -*-

class CreateCounterFramework  < ActiveRecord::Migration
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../counter_table.sql')
    execute sql
  end

  def down
    execute 'DROP FUNCTION counter_table_get_count(v_table_name NAME, v_group_crit BIGINT)'
    execute 'DROP TABLE counter_table'
  end
end

# eof
