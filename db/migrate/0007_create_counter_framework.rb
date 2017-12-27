class CreateCounterFramework < ActiveRecord::Migration[5.0]
  def up
    sql = IO.read(File.dirname(__FILE__) + '/../counter_table.sql')
    execute sql
  end

  def down
    execute <<-SQL
      DROP FUNCTION counter_table_get_count(v_table_name NAME, v_group_crit BIGINT);
      DROP TABLE counter_table;
    SQL
  end
end

# eof
