class AddDescToNotifications < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE notifications ADD COLUMN description TEXT;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE notifications DROP COLUMN description;
    SQL
  end
end

# eof
