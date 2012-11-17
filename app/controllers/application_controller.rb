# -*- encoding: utf-8 -*-

require Rails.root + 'lib/notification_center'
require Rails.root + 'lib/plugin'
require Rails.root + 'lib/tools'

class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_filter :check_forum_access
  protect_from_forgery

  attr_reader :notification_center, :plugin_apis

  def initialize(*args)
    @notification_center = NotificationCenter.new
    @plugin_apis = {}

    plugin_dir = Rails.root + 'lib/plugins/controllers'
    Dir.open(plugin_dir).each do |p|
      next if p[0] == '.'
      eval(IO.read(plugin_dir + p))
    end

    read_syntax_plugins

    super(*args)
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

  helper_method :uconf
  def uconf(name, default = nil)
    ConfigManager.get(name, default, current_user, current_forum)
  end

  helper_method :conf
  def conf(name, default = nil)
    ConfigManager.get(name, default, nil, nil)
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
