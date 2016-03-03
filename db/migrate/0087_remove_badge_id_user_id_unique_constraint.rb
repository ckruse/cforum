# -*- coding: utf-8 -*-

class RemoveBadgeIdUserIdUniqueConstraint < ActiveRecord::Migration
  def up
    execute <<-SQL
ALTER TABLE badges_users
  DROP CONSTRAINT badges_users_user_id_badge_id_key;
    SQL
  end

  def down
    execute <<-SQL
ALTER TABLE badges_users
  ADD CONSTRAINT badges_users_user_id_badge_id_key UNIQUE (user_id, badge_id);
    SQL
  end
end

# eof
