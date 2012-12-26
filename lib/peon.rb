# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, "..", "config", "boot")
require File.join(dir, "..", "config", "environment")

module Peon
  module Tasks

    class PeonTask
      def initialize
        @config_manager = Peon::Grunt.instance.config_manager
        @notification_center = Peon::Grunt.instance.notification_center
      end

      def conf(name, forum, default = nil)
        @config_manager.get(name, default, nil, forum)
      end

      def work_work(args)
      end
    end

  end

end

class Object
  def peon(args = {})
    args = {max_tries: 0, work_done: false, arguments: [], queue_name: 'peon'}.merge(args)

    args[:arguments] = args[:arguments].to_json

    j = CfPeonJob.create!(args)
    CfPeonJob.connection.execute 'NOTIFY ' + args[:queue_name] + ", '" + j.peon_job_id.to_s + "'"

    j
  end
end

# eof
