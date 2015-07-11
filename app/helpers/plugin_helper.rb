# -*- coding: utf-8 -*-

module PluginHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@init_hooks = []
    def init_hooks
      @@init_hooks
    end

    def init_hooks=(val)
      @@init_hooks = val
    end
  end

  @@loaded_plugins = false
  def load_and_init_plugins
    @plugin_apis = {}

    if @@loaded_plugins.blank? or Rails.env == 'development'
      self.class.init_hooks = []

      plugin_dir = Rails.root + 'lib/plugins'
      entries = Dir.entries(plugin_dir).delete_if { |ent| ent[0] == '.' or not File.directory?(plugin_dir + ent) }

      entries.sort.each do |p|
        next if p[0] == '.' or not File.directory?(plugin_dir + p)
        load plugin_dir + p + "#{p}.rb"
      end

      @@loaded_plugins = true
    end

    self.class.init_hooks.each do |hook|
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
end

# eof
