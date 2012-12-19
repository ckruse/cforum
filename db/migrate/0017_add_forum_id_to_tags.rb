# -*- coding: utf-8 -*-

class AddForumIdToTags < ActiveRecord::Migration
  def up
    execute %q{
ALTER TABLE tags ADD COLUMN forum_id BIGINT REFERENCES forums (forum_id) ON UPDATE CASCADE ON DELETE CASCADE;
DROP INDEX tags_tag_name_idx;
CREATE UNIQUE INDEX tags_forum_id_tag_name_idx ON tags (forum_id, tag_name);
    }

    tag_threads = CfTagThread.includes(:thread).all
    tag_threads.each do |tt|
      puts "--- working on " + tt.tag.tag_name
      if tt.tag.forum_id.nil?
        tt.tag.forum_id = tt.thread.forum_id
        tt.tag.save
        next
      end

      if tt.tag.forum_id != tt.thread.forum_id
        CfTag.transaction do
          tag = CfTag.find_by_forum_id_and_tag_name tt.thread.forum_id, tt.tag.tag_name
          tag = CfTag.create!(tag_name: tt.tag.tag_name, forum_id: tt.thread.forum_id) if tag.blank?

          tt.tag_id = tag.tag_id
          tt.save
        end
      end
    end

    execute "ALTER TABLE tags ALTER COLUMN forum_id SET NOT NULL;"
  end

  def down
    execute %q{
DROP INDEX tags_forum_id_tag_name_idx;
CREATE UNIQUE INDEX tags_tag_name_idx ON tags (tag_name);
ALTER TABLE tags DROP COLUMN forum_id;
    }
  end
end

# eof
