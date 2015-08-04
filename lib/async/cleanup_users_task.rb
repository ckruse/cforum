# -*- coding: utf-8 -*-

module Peon
  module Tasks
    class CleanupUsersTask < PeonTask
      def work_work(args)
        users = CfUser.where("confirmed_at IS NULL AND confirmation_sent_at <= NOW() - INTERVAL '7 days'")
        users.each do |u|
          Rails.logger.info 'CleanupUsersTask: deleting user ' + u.username + ' because it is unconfirmed for longer than 7 days'

          CfUser.transaction do
            audit(u, 'autodestroy', nil)
            u.destroy
          end
        end
      end
    end

    Peon::Grunt.instance.periodical(CleanupUsersTask.new, 600)
  end
end

# eof
