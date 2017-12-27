class ChangeAuthorDictSimple < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION search_document_before_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        NEW.ts_author = to_tsvector('simple', NEW.author);
        NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
        NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
        NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

        RETURN NEW;
      END;
      $body$;

      UPDATE search_documents SET ts_author = to_tsvector('simple', author);
    SQL
  end

  def down
    execute <<~SQL
      CREATE OR REPLACE FUNCTION search_document_before_insert() RETURNS trigger LANGUAGE plpgsql AS $body$
      BEGIN
        NEW.ts_author = to_tsvector(NEW.lang::regconfig, NEW.author);
        NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
        NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
        NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

        RETURN NEW;
      END;

      UPDATE search_documents SET ts_author = to_tsvector(lang::regconfig, author);
      $body$;

    SQL
  end
end

# eof
