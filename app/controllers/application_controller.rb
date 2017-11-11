require Rails.root + 'lib/tools'

class ApplicationController < ActionController::Base
  VERSION = '4.4'.freeze

  include ApplicationHelper
  include AuditHelper
  include RightsHelper
  include NotifyHelper
  include TransientInfosHelper
  include ExceptionHelpers
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

  before_action :prepare_exception_notifier, :do_init, :locked?, :handle_redirects,
                :set_forums, :transient_infos, :check_authorizations, :set_css, :set_motd,
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
    redirect_to redirection.destination, status: redirection.http_status if redirection.present?
  end

  def set_forums
    @forums = Forum.visible_forums(current_user)

    return if !params.key?(:view_all) || params[:view_all] == 'false'

    @view_all = true if current_user.try(:admin?) || current_user.try(:moderate?, current_forum)
    set_url_attrib(:view_all, 'yes') if @view_all
  end

  def prefetch?
    %w[x-moz x-purpose purpose].each do |hdr|
      next if request.headers[hdr].blank?
      return true if request.headers[hdr].downcase.in?(%w[prefetch preview])
    end

    false
  end

  def store_location
    return if !request.get? || request.xhr? || prefetch?
    return if request.format != 'text/html' && request.content_type != 'text/html'
    return if request.path.in?(%w[/users/login /users/sign_up /users/password/new /users/password/edit
                                  /users/confirmation /users/logout /users/registration])

    session[:previous_url] = request.fullpath
  end

  def after_sign_in_path_for(_resource)
    session[:previous_url] || root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email])
  end

  private

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = {
      current_user: current_user
    }
  end
end

# eof
