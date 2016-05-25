# -*- coding: utf-8 -*-

class Admin::JobsController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @jobs = sort_query(%w(peon_job_id max_tries tries work_done class_name),
                       PeonJob).
            page(params[:page])

    @stat_jobs = PeonJob.
                 select("DATE_TRUNC('day', created_at) \"day\", COUNT(*) cnt").
                 where(created_at: (Time.zone.now - 30.days)..Time.zone.now).
                 group("DATE_TRUNC('day', created_at)").
                 all
  end

end

# eof
