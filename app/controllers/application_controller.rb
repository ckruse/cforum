# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/plugin'

class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :require_login_from_http_basic, :only => [:login_from_http_basic]
  before_filter :check_admin_access

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

  def login_from_http_basic
    redirect_to root_url, :notice => I18n.t('users.logged_in')
  end

  def set(name, value)
    instance_variable_set('@' + name, value)
  end

  def get(name)
    instance_variable_get('@' + name)
  end

  def uconf(name, default = nil)
    ConfigManager.get(name, default, current_user, current_forum)
  end

  def conf(name, default = nil)
    ConfigManager.get(name, default, nil, nil)
  end

end
