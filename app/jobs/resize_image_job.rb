# -*- coding: utf-8 -*-

require 'fileutils'

class ResizeImageJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find(medium_id)

    FileUtils.mkdir_p Medium.path
    FileUtils.mkdir_p Medium.medium_path
    FileUtils.mkdir_p Medium.thumb_path

    Cocaine::CommandLine.path = Rails.application.config.path_env

    cmd = Cocaine::CommandLine.new('/usr/local/bin/mogrify', '-path :out -thumbnail :size :in')
    cmd.run(in: medium.full_path,
            size: '100x100>',
            out: Medium.thumb_path)

    cmd = Cocaine::CommandLine.new('/usr/local/bin/convert', ':in -scale :size :out')
    cmd.run(in: medium.full_path,
            size: '800x600>',
            out: medium.full_path(:medium))
  end
end

# eof
