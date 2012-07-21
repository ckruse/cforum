class CreateThreadsForumIdIndex < ActiveRecord::Migration
  def up
    add_index 'cforum.threads', :forum_id
  end

  def down
    execute 'DROP INDEX cforum."index_cforum.threads_on_forum_id"'
  end
end