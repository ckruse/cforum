class GenForumStatsJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Forum.select('gen_forum_stats(forum_id::integer)').all.to_a
  end
end

# eof
