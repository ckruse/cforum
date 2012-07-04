class CreateCreatedAtIndex < ActiveRecord::Migration
  def up
    add_index 'cforum.threads', :created_at
  end

  def down
    execute 'DROP INDEX cforum."index_cforum.threads_on_created_at"'
  end
end

# eof