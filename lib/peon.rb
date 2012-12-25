# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

require 'thread'

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('log/peon.log')
ActiveRecord::Base.logger = Rails.logger

module Peon
  class Peon
    def work_work
    end
  end

  class Grunt
    def initialize(queues, num_workers = 1)
      @queues  = queues
      @conds   = {}
      @workers = {}
      @running = true
      @jobs    = {}

      db_conf  = Rails.application.config.database_configuration[Rails.env]
      @db_conn = PG::Connection.open(
        :host     => db_conf['host'],
        :port     => db_conf['port'],
        :dbname   => db_conf['database'],
        :user     => db_conf['username'],
        :password => db_conf['password']
      )

      queues.each do |q|
        @db_conn.execute 'LISTEN ' + q

        @workers[q] = []
        @conds[q]   = Queue.new
        @jobs[q]    = []

        num_workers.times do
          @workers[q] << Thread.new { oversee q }
        end
      end
    end

    def run
      while @running
        wait_for_notify do |event, pid, payload|
          @conds[event].synchronize do
            jobs[event] << payload
            cond.signal
          end
        end
      end
    end

    private

    def oversee(queuename)
      puts "oversee #{queuename} started"

      @conds[queuename].wait_while do

        @running
      end
    end
  end
end

# eof
