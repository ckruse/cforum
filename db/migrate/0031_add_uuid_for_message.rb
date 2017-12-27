class AddUuidForMessage < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN uuid CHARACTER VARYING(250);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages DROP COLUMN uuid;
    SQL
  end
end

# eof
