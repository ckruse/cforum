# -*- coding: utf-8 -*-

class ReadMessages < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE cforum.read_messages (
  read_message_id BIGSERIAL NOT NULL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  message_id BIGINT NOT NULL REFERENCES cforum.messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX read_messages_message_id_user_id_idx ON cforum.read_messages (message_id, user_id);
    }
  end

  def down
    drop_table 'cforum.read_messages'
  end
end

# eof