class AddFormatToMessages < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE messages ADD COLUMN format CHARACTER VARYING(100) NOT NULL DEFAULT 'markdown';
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE messages DROP COLUMN format;
    SQL
  end
end

# eof
