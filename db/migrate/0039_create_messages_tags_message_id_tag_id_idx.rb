class CreateMessagesTagsMessageIdTagIdIdx < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
 CREATE INDEX messages_tags_tag_id_message_id_idx ON messages_tags (tag_id, message_id);
    SQL
  end

  def down
    execute <<-SQL
 DROP INDEX messages_tags_tag_id_message_id_idx;
    SQL
  end
end

# eof
