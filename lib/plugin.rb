# -*- coding: utf-8 -*-

class Plugin
  include CForum::Tools
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

  def flash
    @app_controller.flash
  end

  def current_user
    @app_controller.current_user
  end

  def current_forum
    @app_controller.current_forum
  end

  def params
    @app_controller.params
  end

  def cookies
    @app_controller.get_cookies
  end

  def conf(name, default = nil)
    @app_controller.conf(name, default)
  end

  def uconf(name, default = nil)
    @app_controller.uconf(name, default)
  end

  def register_plugin_api(name, &block)
    @app_controller.register_plugin_api(name, &block)
  end

  def get_plugin_api(name)
    @app_controller.get_plugin_api(name)
  end

  def root_path
    @app_controller.root_path
  end

  def root_url
    @app_controller.root_url
  end

  def redirect_to(*args)
    @app_controller.redirect_to(*args)
  end

  def t(*args)
    I18n.t(*args)
  end

  def application_controller
    @app_controller
  end

  def content_for(name, content)
    @app_controller.content_for(name, content)
  end
end

# eof
