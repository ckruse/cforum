module MotdHelper
  class Motd
    include ParserHelper

    def initialize(content)
      @content = content
    end

    def md_content
      @content
    end

    def md_format
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

    confs = Setting.where(where + ' AND user_id IS NULL', *args).all
    motds = []

    if confs.present?
      confs.each do |conf|
        motds << Motd.new(conf.options['motd']).to_html(self) if conf.options['motd'].present?
      end
    end

    @motds = motds
  end
end

# eof
