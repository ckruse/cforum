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
  include FayeHelper
  include MessageHelper

  before_filter :do_init, :locked?, :check_forum_access, :set_forums,
    :notifications, :run_before_handler, :check_authorizations
  after_filter :run_after_handler

  before_action :configure_permitted_parameters, if: :devise_controller?

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

  def locked?
    if @config_manager.get('locked', false, nil, current_forum) and (not current_user or not current_user.admin?)
      render :locked, status: 500, layout: nil
    end
  end

  def set_forums
    if not current_user
      @forums = CfForum.where("standard_permission = ? OR standard_permission = ?",
                              CfForumGroupPermission::ACCESS_READ,
                              CfForumGroupPermission::ACCESS_WRITE).
        order('UPPER(name) ASC')

    elsif current_user and current_user.admin
      @forums = CfForum.order('UPPER(name) ASC')

    else
      @forums = CfForum.where(
        "(standard_permission IN (?, ?, ?, ?)) OR forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ?)",
        CfForumGroupPermission::ACCESS_READ,
        CfForumGroupPermission::ACCESS_WRITE,
        CfForumGroupPermission::ACCESS_KNOWN_READ,
        CfForumGroupPermission::ACCESS_KNOWN_WRITE,
        current_user.user_id
      ).order('UPPER(name) ASC')
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
    devise_parameter_sanitizer.for(:sign_up) << :email
  end
end

# eof
