# -*- coding: utf-8 -*-

class ForumStat < ActiveRecord::Base
  self.primary_key = 'forum_stat_id'
  self.table_name  = 'forum_stats'

  belongs_to :forum, class_name: 'CfForum', foreign_key: :forum_id
end

# eof
