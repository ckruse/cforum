# -*- coding: utf-8 -*-

class Admin::JobsController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @jobs = sort_query(%w(peon_job_id max_tries tries work_done class_name),
                       PeonJob).
            page(params[:page])

  end

end

# eof
