# -*- coding: utf-8 -*-

module Peon
  module Tasks
    class RefreshStatsTask < PeonTask
      def work_work(args)
        CfForum.select('gen_forum_stats(forum_id::integer)').all.to_a
      end
    end

    # every two hours
    Peon::Grunt.instance.periodical(RefreshStatsTask.new, 7200)
  end
end



# eof
