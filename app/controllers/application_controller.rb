# -*- encoding: utf-8 -*-

$CF_VERSION = '4.4'

require Rails.root + 'lib/tools'
require Rails.root + 'lib/peon'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include AuditHelper
  include RightsHelper
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
  include OwnFilesHelper
  include TitleHelper

  before_action :prepare_exception_notifier, :do_init, :locked?,
                :handle_redirects, :set_forums, :notifications,
                :check_authorizations, :set_css, :set_motd,
                :set_own_files, :set_title_infos
  after_action :store_location

  before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery prepend: true

  #
  # normal stuff
  #

  def do_init
    @app_controller      = self
    @_current_forum      = nil

    CForum::Tools.init
  end

  def locked?
    render :locked, status: 403, layout: nil if (conf('locked') == 'yes') && !current_user.try(:admin?)
  end

  def handle_redirects
    redirection = Redirection.where(path: request.path).first
    redirect_to redirection.destination, status: redirection.http_status unless redirection.blank?
  end

  def set_forums
    if !current_user
      @forums = Forum.where('standard_permission = ? OR standard_permission = ?',
                            ForumGroupPermission::ACCESS_READ,
                            ForumGroupPermission::ACCESS_WRITE)
                  .order('position ASC, UPPER(name) ASC')

    elsif current_user && current_user.admin
      @forums = Forum.order('position ASC, UPPER(name) ASC')

    else
      @forums = Forum.where(
        '(standard_permission IN (?, ?, ?, ?)) OR forum_id IN (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) WHERE user_id = ?)',
        ForumGroupPermission::ACCESS_READ,
        ForumGroupPermission::ACCESS_WRITE,
        ForumGroupPermission::ACCESS_KNOWN_READ,
        ForumGroupPermission::ACCESS_KNOWN_WRITE,
        current_user.user_id
      ).order('position ASC, UPPER(name) ASC')
    end

    forum = current_forum
    user = current_user

    if params.key?(:view_all) && (params[:view_all] != 'false')
      @view_all = true if user.try(:admin?) || user.try(:moderate?, forum)
      set_url_attrib(:view_all, 'yes') if @view_all
    end
  end

  def prefetch?
    %w(x-moz x-purpose purpose).each do |hdr|
      unless request.headers[hdr].blank?
        return true if %w(prefetch preview).include?(request.headers[hdr].downcase)
      end
    end

    false
  end

  def store_location
    return unless request.get?
    if request.path != '/users/login' &&
       request.path != '/users/sign_up' &&
       request.path != '/users/password/new' &&
       request.path != '/users/password/edit' &&
       request.path != '/users/confirmation' &&
       request.path != '/users/logout' &&
       request.path != '/users/registration' &&
       !request.xhr? && !prefetch? &&
       (request.format == 'text/html' ||
        request.content_type == 'text/html')
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for(_resource)
    session[:previous_url] || root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email])
  end

  private

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = {
      current_user: current_user
    }
  end
end

# eof
