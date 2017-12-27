class AddOrderToBadges < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE badges
        ADD COLUMN "order" INT NOT NULL DEFAULT 0;

      UPDATE badges SET "order" = 1 WHERE slug = 'upvote';
      UPDATE badges SET "order" = 2 WHERE slug = 'downvote';
      UPDATE badges SET "order" = 3 WHERE slug = 'seo_profi';
      UPDATE badges SET "order" = 4 WHERE slug = 'visit_close_reopen';
      UPDATE badges SET "order" = 5 WHERE slug = 'create_tag';
      UPDATE badges SET "order" = 6 WHERE slug = 'create_tag_synonym';
      UPDATE badges SET "order" = 7 WHERE slug = 'edit_question';
      UPDATE badges SET "order" = 8 WHERE slug = 'edit_answer';
      UPDATE badges SET "order" = 9 WHERE slug = 'create_close_reopen_vote';
      UPDATE badges SET "order" = 10 WHERE slug = 'moderator_tools';

      UPDATE badges SET "order" = 11 WHERE slug = 'yearling';
      UPDATE badges SET "order" = 12 WHERE slug = 'autobiographer';

      UPDATE badges SET "order" = 13 WHERE slug = 'chisel';
      UPDATE badges SET "order" = 14 WHERE slug = 'brush';
      UPDATE badges SET "order" = 15 WHERE slug = 'quill';
      UPDATE badges SET "order" = 16 WHERE slug = 'pen';
      UPDATE badges SET "order" = 17 WHERE slug = 'printing_press';
      UPDATE badges SET "order" = 18 WHERE slug = 'typewriter';
      UPDATE badges SET "order" = 19 WHERE slug = 'matrix_printer';
      UPDATE badges SET "order" = 20 WHERE slug = 'inkjet_printer';
      UPDATE badges SET "order" = 21 WHERE slug = 'laser_printer';
      UPDATE badges SET "order" = 22 WHERE slug = '1000_monkeys';
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE badges
        DROP COLUMN "order";
    SQL
  end
end

# eof
