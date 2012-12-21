# -*- coding: utf-8 -*-

class CreateNotifications < ActiveRecord::Migration
  def up
    execute %q{
CREATE TABLE notifications (
  notification_id BIGSERIAL NOT NULL PRIMARY KEY,
  recipient_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  is_read BOOLEAN NOT NULL DEFAULT false,
  subject CHARACTER VARYING(250) NOT NULL,
  path CHARACTER VARYING(250) NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE INDEX notifications_owner_idx ON notifications (recipient_id);
    }
  end

  def down
    execute "DROP TABLE notifications;"
  end
end

# eof
