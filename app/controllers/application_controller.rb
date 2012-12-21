# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/tools'
require Rails.root + 'lib/plugin'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include PluginHelper
  include NotifyHelper
  include AuthorizeStd

  before_filter :do_init, :check_forum_access, :run_before_handler
  after_filter :run_after_handler
  protect_from_forgery

  attr_reader :notification_center, :plugin_apis

  helper_method :uconf, :conf

  BEFORE_HANDLER = "before_handler"
  AFTER_HANDLER  = "after_handler"

  #
  # Plugins
  #


  def run_before_handler
    notification_center.notify(BEFORE_HANDLER)
  end

  def run_after_handler
    notification_center.notify(AFTER_HANDLER)
  end


  #
  # normal stuff
  #

  def do_init
    @notification_center = NotificationCenter.new
    @config_manager      = ConfigManager.new
    @view_all            = false
    @_current_forum      = nil

    mod_view_paths
    load_and_init_plugins
  end

  def uconf(name, default = nil)
    @config_manager.get(name, default, current_user, current_forum)
  end

  def conf(name, default = nil)
    @config_manager.get(name, default, nil, nil)
  end

end

# eof
