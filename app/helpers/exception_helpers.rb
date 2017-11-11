module ExceptionHelpers
  def render_500(e = nil)
    if e
      logger.fatal 'URL: ' + request.method + ' ' + request.url +
                   "\nError: " + e.message + "\nStacktrace: " + e.backtrace.join("\n") +
                   "\nUser: " + current_user.inspect + "\nSession: " + session.inspect +
                   "\nParams: " + params.inspect
    end

    respond_to do |format|
      format.html { render template: 'errors/500', status: 500 }
      format.json { render json: {}, status: 500 }
    end
  end

  def render_404(e = nil)
    if e
      logger.warn 'URL: ' + request.method + ' ' + request.url +
                  "\nError: " + e.message + "\nStacktrace: " + e.backtrace.join("\n") +
                  "\nUser: " + current_user.inspect + "\nSession: " + session.inspect +
                  "\nParams: " + params.inspect
    end

    respond_to do |format|
      format.html { render template: 'errors/404', status: 404 }
      format.json { render json: {}, status: 404 }
    end
  end

  def render_403(e = nil)
    if e
      logger.warn 'URL: ' + request.method + ' ' + request.url +
                  "\nError: " + e.message + "\nStacktrace: " + e.backtrace.join("\n") +
                  "\nUser: " + current_user.inspect + "\nSession: " + session.inspect +
                  "\nParams: " + params.inspect
    end

    respond_to do |format|
      format.html { render template: 'errors/403', status: 403 }
      format.json { render json: {}, status: 403 }
    end
  end
end

# eof
