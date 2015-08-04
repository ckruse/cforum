# -*- coding: utf-8 -*-

class MotdPlugin < Plugin
  class Motd
    include ParserHelper

    def initialize(content)
      @content = content
    end

    def get_content
      @content
    end

    def get_format
      'markdown'
    end

    def id_prefix
      'motd'
    end
  end


  def before_handler
    where = 'forum_id IS NULL'
    args = []

    if current_forum
      where << ' OR forum_id = ?'
      args << current_forum.forum_id
    end

    confs = CfSetting.where(where + ' AND user_id IS NULL', *args).all
    motds = []

    unless confs.blank?
      confs.each do |conf|
        motds << Motd.new(conf.options['motd']).to_html(@app_controller) unless conf.options['motd'].blank?
      end
    end

    set('motds', motds)
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  motd_plugin = MotdPlugin.new(app_controller)
  app_controller.notification_center.
    register_hook(ApplicationController::BEFORE_HANDLER, motd_plugin)
end

# eof
