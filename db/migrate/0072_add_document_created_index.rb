# -*- coding: utf-8 -*-

class AddDocumentCreatedIndex < ActiveRecord::Migration
  def up
    execute <<-SQL
CREATE INDEX search_documents_document_created_idx ON search_documents(document_created);
    SQL
  end

  def down
    execute <<-SQL
DROP INDEX search_documents_document_created_idx;
    SQL
  end
end

# eof
