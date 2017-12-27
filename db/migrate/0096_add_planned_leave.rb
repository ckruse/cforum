class AddPlannedLeave < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE attendees ADD COLUMN planned_leave TIMESTAMP WITHOUT TIME ZONE;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE attendees DROP COLUMN planned_leave;
    SQL
  end
end
