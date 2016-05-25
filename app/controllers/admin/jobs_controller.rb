# -*- coding: utf-8 -*-

class Admin::JobsController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @jobs = sort_query(%w(peon_job_id max_tries tries work_done class_name),
                       PeonJob).
            page(params[:page])

    @stat_jobs = PeonJob.
                 select("DATE_TRUNC('day', timestamp2local(created_at, '" + Time.zone.name + "')) \"day\", COUNT(*) cnt").
                 where(created_at: (Time.zone.now - 30.days)..Time.zone.now).
                 group("DATE_TRUNC('day', timestamp2local(created_at, '" + Time.zone.name + "'))").
                 all
  end

end

# eof
