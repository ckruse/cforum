class MissingForeignKeyIndexes < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE INDEX messages_editor_id_idx ON messages(editor_id);
      CREATE INDEX search_documents_user_id_idx ON search_documents(user_id);
      CREATE INDEX read_messages_user_id_idx ON read_messages(user_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX messages_editor_id_idx;
      DROP INDEX search_documents_user_id_idx;
      DROP INDEX read_messages_user_id_idx;
    SQL
  end
end

# eof
