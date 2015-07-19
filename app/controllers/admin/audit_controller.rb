# -*- coding: utf-8 -*-

class Admin::AuditController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @audits = CfAuditing.
              preload(:user).
              order('created_at DESC').
              page(params[:page]).
              per(conf('pagination').to_i)
  end

  def show
  end
end

# eof
