# -*- coding: utf-8 -*-

dir = File.dirname(__FILE__)
require File.join(dir, '..', 'config_manager')
require Rails.root + 'app/helpers/parser_helper.rb'

require 'thread'
require 'singleton'

Thread.abort_on_exception = true

module Peon
  class Grunt
    include Singleton

    attr_accessor :config_manager

    def initialize
      @queues  = []
      @conds   = {}
      @locks   = {}
      @workers = {}
      @running = true
      @jobs    = {}

      @config_manager = ConfigManager.new(false)

      db_conf  = Rails.application.config.database_configuration[Rails.env]
      @db_conn = PG::Connection.open(
        host: db_conf['host'],
        port: db_conf['port'],
        dbname: db_conf['database'],
        user: db_conf['username'],
        password: db_conf['password']
      )
    end

    def init(queues, num_workers = 1)
      @queues = queues

      # initialize queues, locks, conditionals and workers
      queues.each do |q|
        Rails.logger.debug "LISTEN #{q}"
        @db_conn.exec "LISTEN #{q}"

        @workers[q] = []
        @conds[q]   = ConditionVariable.new
        @locks[q]   = Mutex.new
        @jobs[q]    = []

        num_workers.times do
          @workers[q] << Thread.new { monitor q }
        end
      end

      # load tasks
      tasks_dir = File.join(File.dirname(__FILE__), '..', 'async')
      Dir.open(tasks_dir).each do |p|
        next if (p[0] == '.') || !File.file?(tasks_dir + '/' + p) || p !~ /_task\.rb$/
        load tasks_dir + "/#{p}"
      end

      # load old tasks
      jobs = PeonJob.where('work_done = false AND max_tries > tries').all
      jobs.each do |j|
        @jobs[j.queue_name] << j
      end
    end

    def periodical(obj, slice = 180)
      Rails.logger.debug "grunt periodical startup: #{obj.inspect}"
      Thread.start do
        while @running
          Rails.logger.debug "grunt periodical: #{obj.inspect}"

          begin
            obj.work_work({})
          rescue => e
            Rails.logger.error "grunt run: periodical #{obj.inspect}: #{e.message}\n#{e.backtrace.join("\n")}"
            send_exception_mail(e)
          end

          sleep slice
          Rails.logger.debug "grunt periodical: wakeup: #{obj.inspect}"
        end
      end
    end

    def run
      @jobs.keys.each do |k|
        unless @jobs[k].empty?
          Rails.logger.debug "Broadcasting on #{k}"
          @conds[k].broadcast
        end
      end

      while @running
        @db_conn.wait_for_notify do |event, _pid, payload|
          Rails.logger.info "grunt run: event: #{event}, payload: #{payload}"

          begin
            job = PeonJob.find payload

            @locks[event].synchronize do
              @jobs[event] << job
              @conds[event].signal
            end
          rescue => e
            Rails.logger.error "grunt run: queue #{event}: #{e.message}\n#{e.backtrace.join("\n")}"
            send_exception_mail(e)
          end
        end # wait_for_notify
      end # while @running
    end

    private

    def monitor(queuename)
      Rails.logger.info "grunt monitor: queue #{queuename} started"

      while @running
        job = nil
        @locks[queuename].synchronize do
          if @jobs[queuename].empty?
            @conds[queuename].wait(@locks[queuename])
            Rails.logger.debug "grunt monitor: wakeup: queue #{queuename}"
          end

          job = @jobs[queuename].shift
        end

        Rails.logger.debug "grunt monitor: job #{job.inspect}"

        next unless job
        begin
          klass = Tasks.const_get(job.class_name)
          klass.new.work_work(JSON.parse(job.arguments))
          job.update_attributes(work_done: true)
        rescue => e
          Rails.logger.error "grunt monitor: queue #{queuename}: #{e.message}\n#{e.backtrace.join("\n")}"
          send_exception_mail(e)

          job.errstr     = e.message
          job.stacktrace = e.backtrace.join("\n")
          job.tries     += 1
          job.save

          if job.max_tries > job.tries
            @locks[queuename].synchronize { @jobs[queuename] << job }
          end
        end
        # if job
      end # while @running
    end # def @monitor

    def send_exception_mail(exception)
      ExceptionMailer.new_exception(exception).deliver_now
    end
  end
end

# eof
