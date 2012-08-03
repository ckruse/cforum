# -*- encoding: utf-8 -*-

class CreateCounterFramework  < ActiveRecord::Migration
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../count_threads.sql')
    execute sql
  end

  def down
    execute 'DROP FUNCTION cforum.counter_table_remove_count_trigger(v_table_name name, v_crit_column name, v_group_crit BIGINT)'
    execute 'DROP FUNCTION cforum.counter_table_create_count_trigger(v_table_name name, v_crit_column name, v_group_crit BIGINT)'
    execute 'DROP FUNCTION cforum.counter_table_get_count(v_table_name NAME, v_group_crit BIGINT)'
    execute 'DROP FUNCTION cforum.counter_table__truncate_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.counter_table__delete_trigger() CASCADE'
    execute 'DROP FUNCTION cforum.counter_table__insert_trigger() CASCADE'
    execute 'DROP TABLE cforum.counter_table CASCADE'
  end
end

# eof