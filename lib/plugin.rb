class Plugin
  def initialize(app_controller)
    @app_controller = app_controller
  end

  def notify(name, *args)
    if respond_to?(name.to_sym)
      send(name.to_sym, *args)
    else
      raise CForum::NotFoundException.new # TODO: more specific exception
    end
  end

  def set(name, val)
    @app_controller.set(name, val)
  end

  def get(name)
    @app_controller.get(name)
  end

  def current_user
    @app_controller.current_user
  end

end
