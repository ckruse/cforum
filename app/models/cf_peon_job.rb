# -*- encoding: utf-8 -*-

class CfPeonJob < ActiveRecord::Base
  self.primary_key = 'peon_job_id'
  self.table_name  = 'peon_jobs'

  attr_accessible :peon_job_id, :queue_name, :max_tries, :tries,
    :work_done, :class_name, :arguments, :errstr, :stacktrace

  validates_presence_of :queue_name, :class_name, :arguments
end

# eof
