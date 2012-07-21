class RemoveInvisible < ActiveRecord::Migration
  def up
    execute 'UPDATE cforum.messages SET deleted = invisible'
    remove_column 'cforum.messages', :invisible
  end

  def down
    add_column 'cforum.messages', :invisible, :boolean, null: false, default: false
    execute 'UPDATE cforum.messages SET invisible = deleted'
  end
end
