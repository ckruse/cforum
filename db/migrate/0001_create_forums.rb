class CreateForums < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TABLE forums (
        forum_id BIGSERIAL PRIMARY KEY NOT NULL,
        slug CHARACTER VARYING(255) NOT NULL,
        short_name CHARACTER VARYING(255) NOT NULL,

        public BOOLEAN NOT NULL DEFAULT true,

        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,

        name CHARACTER VARYING NOT NULL,
        description CHARACTER VARYING
      );

      CREATE UNIQUE INDEX forums_slug_idx ON forums (slug);
    SQL
  end

  def down
    drop_table 'forums'
  end
end
