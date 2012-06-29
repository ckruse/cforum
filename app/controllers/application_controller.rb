class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :require_login_from_http_basic, :only => [:login_from_http_basic]

  def login_from_http_basic
    redirect_to root_url, :notice => 'Login from basic auth successful'
  end
end
