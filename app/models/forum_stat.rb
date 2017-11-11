class ForumStat < ApplicationRecord
  self.primary_key = 'forum_stat_id'
  self.table_name  = 'forum_stats'

  belongs_to :forum
end

# eof
