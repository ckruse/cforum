# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/tools'
require Rails.root + 'lib/plugin'

class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_filter :do_init, :check_forum_access, :run_before_handler
  after_filter :run_after_handler
  protect_from_forgery

  attr_reader :notification_center, :plugin_apis

  BEFORE_HANDLER = "before_handler"
  AFTER_HANDLER  = "after_handler"

  #
  # Plugins
  #

  @@init_hooks = []
  @@loaded_plugins = false
  def self.init_hooks
    @@init_hooks
  end

  def run_before_handler
    notification_center.notify(BEFORE_HANDLER)
  end

  def run_after_handler
    notification_center.notify(AFTER_HANDLER)
  end

  def load_and_init_plugins
    @plugin_apis = {}

    if @@loaded_plugins.blank? or Rails.env != 'production'
      @@init_hooks = []

      plugin_dir = Rails.root + 'lib/plugins/controllers'
      Dir.open(plugin_dir).each do |p|
        next if p[0] == '.' or not File.directory?(plugin_dir + p)
        load plugin_dir + p + "#{p}.rb"
      end

      read_syntax_plugins

      @@loaded_plugins = true
    end

    @@init_hooks.each do |hook|
      hook.call(self)
    end
  end

  def register_plugin_api(name, &block)
    @plugin_apis[name] = block
  end

  def get_plugin_api(name)
    @plugin_apis[name]
  end

  def set(name, value)
    instance_variable_set('@' + name, value)
  end

  def get(name)
    instance_variable_get('@' + name)
  end

  def mod_view_paths
    paths = [Rails.root + "lib/plugins/controllers/"]

    rest = view_paths[0..-1]
    paths += rest if rest

    ActionMailer::Base.prepend_view_path(Rails.root + "lib/plugins/controllers/")
    lookup_context.view_paths = view_paths = ActionView::PathSet.new(paths)
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

  helper_method :uconf
  def uconf(name, default = nil)
    @config_manager.get(name, default, current_user, current_forum)
  end

  helper_method :conf
  def conf(name, default = nil)
    @config_manager.get(name, default, nil, nil)
  end

  def check_forum_access
    forum = current_forum
    user = current_user

    return if forum.blank?
    return if forum.public
    return if user and user.admin

    unless user.blank?
      user.rights.each do |r|
        if r.forum_id == forum.forum_id
          if %w{new edit create update destroy}.include?(action_name)
            return if %w{moderator write}.include?(r.permission)
          else
            return if %w{moderator read write}.include?(r.permission)
          end
        end
      end
    end

    raise CForum::ForbiddenException.new
  end
end
