# -*- coding: utf-8 -*-

class OpenedClosedThreads < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE cforum.opened_closed_threads (
  opened_closed_thread_id BIGSERIAL NOT NULL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES cforum.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  thread_id BIGINT NOT NULL REFERENCES cforum.threads(thread_id) ON DELETE CASCADE ON UPDATE CASCADE,
  state CHARACTER VARYING(10) NOT NULL
);

CREATE UNIQUE INDEX opened_closed_threads_thread_id_user_id_idx ON cforum.opened_closed_threads (thread_id, user_id);
    }
  end

  def down
    drop_table 'cforum.opened_closed_threads'
  end
end

# eof