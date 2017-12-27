class AddBadges < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TYPE badge_medal_type_t AS ENUM('bronze', 'silver', 'gold');
      CREATe TYPE badge_type_t AS ENUM('custom', 'upvote', 'downvote', 'retag',
                                       'flag', 'visit_close_reopen', 'create_tag',
                                       'edit_question', 'edit_answer',
                                       'create_tag_synonym', 'create_close_reopen_vote',
                                       'moderator_tools');

      CREATE TABLE badges (
        badge_id SERIAL NOT NULL PRIMARY KEY,
        score_needed INTEGER NOT NULL,
        name CHARACTER VARYING NOT NULL,
        description TEXT,
        slug CHARACTER VARYING NOT NULL UNIQUE,
        badge_type badge_type_t NOT NULL,
        badge_medal_type badge_medal_type_t NOT NULL DEFAULT 'bronze',
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      );

      CREATE UNIQUE INDEX badges_badge_type_uniqueness ON badges(badge_type) WHERE badge_type != 'custom';

      CREATE TABLE badges_users (
        badge_user_id BIGSERIAL NOT NULL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
        badge_id INTEGER NOT NULL REFERENCES badges(badge_id) ON DELETE CASCADE ON UPDATE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        UNIQUE(user_id, badge_id)
      );
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE badges_users;
      DROP TABLE badges;
      DROP TYPE badge_type_t;
      DROP TYPE badge_medal_type_t;
    SQL
  end
end

# eof
