# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/tools'
require Rails.root + 'lib/plugin'
require Rails.root + 'lib/peon'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include PluginHelper
  include NotifyHelper
  include AuthorizeStd
  include ExceptionHelpers

  before_filter :do_init, :check_forum_access, :notifications, :scores, :run_before_handler
  after_filter :run_after_handler
  protect_from_forgery

  attr_reader :notification_center, :plugin_apis, :view_all

  helper_method :uconf, :conf, :view_all

  BEFORE_HANDLER = "before_handler"
  AFTER_HANDLER  = "after_handler"


  if Rails.env == 'production'
    rescue_from StandardError, :with => :render_500

    rescue_from ActiveRecord::RecordNotFound, AbstractController::ActionNotFound, CForum::NotFoundException, :with => :render_404
    rescue_from CForum::ForbiddenException, :with => :render_403
  end

  #
  # Plugins
  #

  def get_cookies
    cookies
  end

  def run_before_handler
    notification_center.notify(BEFORE_HANDLER)
  end

  def run_after_handler
    notification_center.notify(AFTER_HANDLER)
  end


  #
  # normal stuff
  #

  def self.instance
    @@instance
  end

  def do_init
    ConfigManager.reset_instance

    @notification_center = NotificationCenter.new
    @config_manager      = ConfigManager.instance
    @view_all            = false
    @_current_forum      = nil

    @@instance           = self

    mod_view_paths
    load_and_init_plugins

    CForum::Tools.init
  end

  def uconf(name, default = nil)
    @config_manager.get(name, default, current_user, current_forum)
  end

  def conf(name, default = nil)
    @config_manager.get(name, default, nil, current_forum)
  end

  def scores
    @score = CfScore.where(user_id: current_user.user_id).sum('value') if current_user
  end

end

# eof
