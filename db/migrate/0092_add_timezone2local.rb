class AddTimezone2local < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION timestamp2local(ts_p TIMESTAMP WITHOUT TIME ZONE, tz_p CHARACTER VARYING) RETURNS TIMESTAMP WITH TIME ZONE AS $fun$
      BEGIN
        RETURN (SELECT (ts_p AT TIME ZONE 'UTC') AT TIME ZONE tz_p);
      END;
      $fun$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION timestamp2local(ts_p TIMESTAMP WITHOUT TIME ZONE);
    SQL
  end
end

# eof
