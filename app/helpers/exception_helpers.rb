# -*- coding: utf-8 -*-

module ExceptionHelpers
  def render_500
    respond_to do |format|
      format.html { render template: 'errors/500', status: 500 }
      format.json { render json: {}, status: 500 }
    end
  end

  def render_404
    respond_to do |format|
      format.html { render template: 'errors/404', status: 404 }
      format.json { render json: {}, status: 404 }
    end
  end

  def render_403
    respond_to do |format|
      format.html { render template: 'errors/403', status: 403 }
      format.json { render json: {}, status: 403 }
    end
  end
end

# eof