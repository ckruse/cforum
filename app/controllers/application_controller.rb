# -*- encoding: utf-8 -*-

$CF_VERSION = '4.2'

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/tools'
require Rails.root + 'lib/plugin'
require Rails.root + 'lib/peon'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include AuditHelper
  include RightsHelper
  include PluginHelper
  include NotifyHelper
  include ExceptionHelpers
  include PublishHelper
  include MessageHelper
  include SortablesHelper
  include SortingHelper
  include CacheHelper
  include MarkReadHelper
  include InvisibleHelper
  include CssHelper
  include MotdHelper

  before_filter :do_init, :locked?, :set_forums, :notifications,
                :run_before_handler, :check_authorizations, :set_css, :set_motd
  after_filter :run_after_handler, :store_location

  before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery

  attr_reader :notification_center, :plugin_apis, :view_all

  helper_method :uconf, :conf, :view_all

  BEFORE_HANDLER = "before_handler"
  AFTER_HANDLER  = "after_handler"

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

  def do_init
    @app_controller      = self
    @notification_center = NotificationCenter.new
    @config_manager      = ConfigManager.new
    @view_all            = false
    @_current_forum      = nil

    load_and_init_plugins

    CForum::Tools.init
  end

  def uconf(name)
    @config_manager.get(name, current_user, current_forum)
  end

  def conf(name)
    @config_manager.get(name, nil, current_forum)
  end

  def locked?
    if conf('locked') == "yes" and (not current_user or not current_user.admin?)
      render :locked, status: 500, layout: nil
    end
  end

  def set_forums
    if not current_user
      @forums = CfForum.where("standard_permission = ? OR standard_permission = ?",
                              CfForumGroupPermission::ACCESS_READ,
                              CfForumGroupPermission::ACCESS_WRITE).
        order('position ASC, UPPER(name) ASC')

    elsif current_user and current_user.admin
      @forums = CfForum.order('position ASC, UPPER(name) ASC')

    else
      @forums = CfForum.where(
        "(standard_permission IN (?, ?, ?, ?)) OR forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ?)",
        CfForumGroupPermission::ACCESS_READ,
        CfForumGroupPermission::ACCESS_WRITE,
        CfForumGroupPermission::ACCESS_KNOWN_READ,
        CfForumGroupPermission::ACCESS_KNOWN_WRITE,
        current_user.user_id
      ).order('position ASC, UPPER(name) ASC')
    end

    forum = current_forum
    user = current_user

    if params.has_key?(:view_all) and params[:view_all] != 'false'
      if forum.blank?
        @view_all = true if not user.blank? and user.admin?
      else
        @view_all = forum.moderator?(user)
      end

      set_url_attrib(:view_all, 'yes') if @view_all
    end
  end


  def is_prefetch
    %w(x-moz x-purpose purpose).each do |hdr|
      unless request.headers[hdr].blank?
        return true if %w(prefetch preview).include?(request.headers[hdr].downcase)
      end
    end

    return false
  end

  def store_location
    return unless request.get?
    if (request.path != "/users/login" &&
        request.path != "/users/sign_up" &&
        request.path != "/users/password/new" &&
        request.path != "/users/password/edit" &&
        request.path != "/users/confirmation" &&
        request.path != "/users/logout" &&
        request.path != "/users/registration" &&
        !request.xhr? && !is_prefetch &&
        (request.format == "text/html" ||
         request.content_type == "text/html"))
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
    devise_parameter_sanitizer.for(:sign_up) << :email
  end
end

# eof
