# -*- coding: utf-8 -*-

class VotingChecks < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE votes (
  vote_id BIGSERIAL NOT NULL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE,
  vtype CHARACTER VARYING(50) NOT NULL
);

CREATE UNIQUE INDEX votes_user_id_message_id_idx ON votes (user_id, message_id);
    }
  end

  def down
    execute "DROP TABLE votes;"
  end
end

# eof
