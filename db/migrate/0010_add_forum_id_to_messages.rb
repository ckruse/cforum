class AddForumIdToMessages < ActiveRecord::Migration
  def up
    add_column 'cforum.messages', :forum_id, :integer, limit: 8
    execute 'UPDATE cforum.messages SET forum_id = (SELECT forum_id FROM cforum.threads WHERE cforum.threads.thread_id = cforum.messages.thread_id)'
    change_column 'cforum.messages', :forum_id, :integer, limit: 8, null: false
    execute "ALTER TABLE cforum.messages ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES cforum.forums(forum_id) ON DELETE CASCADE ON UPDATE CASCADE"
    add_index 'cforum.messages', [:forum_id, :updated_at]
  end

  def down
    remove_column 'cforum.messages', :forum_id
  end
end
