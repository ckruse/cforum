# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/plugin'

class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_filter :check_admin_access
  protect_from_forgery

  attr_reader :notification_center

  def check_admin_access
    cu = current_user
    if cu and cu.admin and (session[:view_all] || params[:view_all])
      CfThread.view_all = true
      CfMessage.view_all = true
    end
  end

  def initialize(*args)
    @notification_center = NotificationCenter.new

    plugin_dir = Rails.root + 'lib/plugins'
    Dir.open(plugin_dir).each do |p|
      next if p[0] == '.'
      eval(IO.read(plugin_dir + p))
    end

    super(*args)
  end

  def set(name, value)
    instance_variable_set('@' + name, value)
  end

  def get(name)
    instance_variable_get('@' + name)
  end

end
