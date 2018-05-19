class AddMissingUniqueConstraintToModerationQueueMessageId < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      DROP INDEX moderation_queue_message_id_idx;
      CREATE UNIQUE INDEX moderation_queue_message_id_idx ON moderation_queue (message_id);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX moderation_queue_message_id_idx;
      CREATE UNIQUE INDEX moderation_queue_message_id_idx ON moderation_queue (message_id) WHERE cleared = true;
    SQL
  end
end
