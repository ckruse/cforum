class CreateEvents < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TABLE events (
        event_id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT,
        maps_link TEXT,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        visible BOOLEAN NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE UNIQUE INDEX ON events(LOWER(name));

      CREATE TABLE attendees (
        attendee_id SERIAL PRIMARY KEY,
        event_id INT NOT NULL REFERENCES events(event_id),
        user_id BIGINT REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
        name TEXT NOT NULL,
        comment TEXT,
        starts_at TEXT,
        planned_start TIMESTAMP,
        planned_arrival TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        seats INT,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        UNIQUE(event_id, user_id)
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE attendees;
      DROP TABLE events;
    SQL
  end
end
