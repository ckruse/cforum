class CreateIndexes < ActiveRecord::Migration
  def up
    add_index 'cforum.threads', :tid
    add_index 'cforum.threads', :archived

    add_index 'cforum.messages', :thread_id
    add_index 'cforum.messages', :mid

    add_index 'cforum.settings', :name
    add_index 'cforum.settings', :user_id
    add_index 'cforum.settings', :forum_id
  end

  def down
    execute 'DROP INDEX cforum."index_cforum.messages_on_mid"'
    execute 'DROP INDEX cforum."index_cforum.messages_on_thread_id"'

    execute 'DROP INDEX cforum."index_cforum.threads_on_tid"'
    execute 'DROP INDEX cforum."index_cforum.threads_on_archived"'

    execute 'DROP INDEX cforum."index_cforum.settings_on_forum_id"'
    execute 'DROP INDEX cforum."index_cforum.settings_on_name"'
    execute 'DROP INDEX cforum."index_cforum.settings_on_user_id"'
  end
end