# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, "..", "config", "boot")
require File.join(dir, "..", "config", "environment")

module Peon
  module Tasks

    class Peon
      def work_work(args)
      end
    end

  end

end

class Object
  def peon(task_name, args = {})
    args = {max_tries: 0, work_done: false, arguments: [], queue_name: 'peon'}.merge(args)
    j = CfPeonJob.create!(args)
  end
end

# eof
