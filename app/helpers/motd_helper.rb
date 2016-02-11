# -*- coding: utf-8 -*-

module MotdHelper
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

  def set_motd
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
        motds << Motd.new(conf.options['motd']).to_html(self) unless conf.options['motd'].blank?
      end
    end

    @motds = motds
  end
end

# eof
