require 'fileutils'

class ResizeImageJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find(medium_id)

    FileUtils.mkdir_p Medium.path
    FileUtils.mkdir_p Medium.medium_path
    FileUtils.mkdir_p Medium.thumb_path

    Terrapin::CommandLine.path = Rails.application.config.path_env

    cmd = Terrapin::CommandLine.new('mogrify', '-auto-orient -strip -path :out -thumbnail :size :in')
    cmd.run(in: medium.full_path,
            size: '100x100>',
            out: Medium.thumb_path)

    cmd = Terrapin::CommandLine.new('mogrify', '-auto-orient -strip -path :out -scale :size :in')
    cmd.run(in: medium.full_path,
            size: '800x600>',
            out: Medium.medium_path)
  rescue Terrapin::ExitStatusError => e
    Rails.logger.error e.message
  end
end

# eof
