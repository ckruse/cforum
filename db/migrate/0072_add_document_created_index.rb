class AddDocumentCreatedIndex < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE INDEX search_documents_document_created_idx ON search_documents(document_created);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX search_documents_document_created_idx;
    SQL
  end
end

# eof
