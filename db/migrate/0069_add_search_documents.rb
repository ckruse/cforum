class AddSearchDocuments < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE search_sections (
        search_section_id SERIAL NOT NULL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        position INTEGER NOT NULL,
        active_by_default BOOLEAN NOT NULL DEFAULT false,
        forum_id BIGINT REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE
      );

      CREATE TABLE search_documents (
        search_document_id BIGSERIAL NOT NULL PRIMARY KEY,
        search_section_id INTEGER NOT NULL REFERENCES search_sections(search_section_id) ON DELETE CASCADE ON UPDATE CASCADE,
        reference_id BIGINT UNIQUE,
        forum_id BIGINT REFERENCES forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE,
        user_id BIGINT REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        url TEXT UNIQUE NOT NULL,
        relevance FLOAT NOT NULL,
        author TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        ts_title TSVECTOR NOT NULL,
        ts_content TSVECTOR NOT NULL,
        ts_document TSVECTOR NOT NULL,
        document_created TIMESTAMP WITHOUT TIME ZONE,
        lang TEXT NOT NULL,
        tags text[] NOT NULL
      );

      CREATE INDEX search_documents_document_idx ON search_documents USING gin(ts_document);
      CREATE INDEX search_documents_content_idx ON search_documents USING gin(ts_content);
      CREATE INDEX search_documents_title_idx ON search_documents USING gin(ts_title);

      CREATE FUNCTION search_document_before_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
        NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
        NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

        RETURN NEW;
      END;
      $body$;

      CREATE TRIGGER search_documents__before_insert_trigger
        BEFORE INSERT
        ON search_documents
        FOR EACH ROW
        EXECUTE PROCEDURE search_document_before_insert();

      CREATE TRIGGER search_documents__before_update_trigger
        BEFORE UPDATE
        ON search_documents
        FOR EACH ROW
        EXECUTE PROCEDURE search_document_before_insert();


      CREATE INDEX search_documents_lower_author_idx ON search_documents(LOWER(author));
      CREATE INDEX search_documents_tags_idx ON search_documents USING GIN (tags);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE search_documents;
      DROP TABLE search_sections;
      DROP FUNCTION search_document_before_insert();
    SQL
  end
end

# eof
