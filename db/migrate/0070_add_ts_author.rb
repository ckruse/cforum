class AddTsAuthor < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL

      ALTER TABLE search_documents ADD COLUMN ts_author TSVECTOR;

      CREATE INDEX search_documents_author_idx ON search_documents USING gin(ts_author);

      CREATE OR REPLACE FUNCTION search_document_before_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        NEW.ts_author = to_tsvector(NEW.lang::regconfig, NEW.author);
        NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
        NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
        NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

        RETURN NEW;
      END;
      $body$;

      DROP INDEX search_documents_lower_author_idx;

      UPDATE search_documents SET ts_author = to_tsvector(lang::regconfig, author);
      ALTER TABLE search_documents ALTER COLUMN ts_author SET NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      CREATE INDEX search_documents_lower_author_idx ON search_documents(LOWER(author));
      ALTER TABLE search_documents DROP COLUMN ts_author;

      CREATE OR REPLACE FUNCTION search_document_before_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
        NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
        NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

        RETURN NEW;
      END;
      $body$;

    SQL
  end
end

# eof
