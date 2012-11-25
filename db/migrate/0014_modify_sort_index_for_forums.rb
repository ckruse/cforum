# -*- coding: utf-8 -*-

class ModifySortIndexForForums < ActiveRecord::Migration
  def up
    execute %q{
CREATE INDEX messages_forum_id_created_at_idx ON cforum.messages (forum_id, created_at);
DROP INDEX cforum.messages_forum_id_updated_at_idx;
    }
  end

  def down
    execute %q{
CREATE INDEX messages_forum_id_updated_at_idx ON cforum.messages (forum_id, updated_at);
DROP INDEX cforum.messages_forum_id_created_at_idx;
    }
  end
end

# eof