require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/plugin'

class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :require_login_from_http_basic, :only => [:login_from_http_basic]

  attr_reader :notification_center

  def initialize(*args)
    @notification_center = NotificationCenter.new

    plugin_dir = Rails.root + 'lib/plugins'
    Dir.open(plugin_dir).each do |p|
      next if p[0] == '.'
      eval(IO.read(plugin_dir + p))
    end

    super(*args)
  end

  def login_from_http_basic
    redirect_to root_url, :notice => 'Login from basic auth successful'
  end

  def set(name, value)
    instance_variable_set('@' + name, value)
  end

  def get(name)
    instance_variable_get('@' + name)
  end

end
