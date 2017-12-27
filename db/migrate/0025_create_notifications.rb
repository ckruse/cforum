class CreateNotifications < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE notifications (
        notification_id BIGSERIAL NOT NULL PRIMARY KEY,
        recipient_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        is_read BOOLEAN NOT NULL DEFAULT false,
        subject CHARACTER VARYING(250) NOT NULL,
        path CHARACTER VARYING(250) NOT NULL,
        icon CHARACTER VARYING(250),
        oid BIGINT NOT NULL,
        otype CHARACTER VARYING(100) NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE,
        updated_at TIMESTAMP WITHOUT TIME ZONE
      );

      CREATE INDEX notifications_recipient_id_oid_idx ON notifications (recipient_id, oid);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE notifications;
    SQL
  end
end

# eof
