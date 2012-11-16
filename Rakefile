#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

class Rake::Task
  def overwrite(&block)
    @full_comment = nil
    @actions.clear
    prerequisites.clear
    enhance(&block)
  end

  def abandon
    @full_comment = nil
    prerequisites.clear
    @actions.clear
  end
end

Cforum::Application.load_tasks

namespace :db do
  namespace :structure do |schema|
    schema[:dump].abandon

    task :dump => :environment do
      config = ActiveRecord::Base.configurations[Rails.env]

      args = "-sxO"
      args << ' -h ' + config['host'] unless config['host'].blank?
      args << ' -U ' + config['user'] unless config['user'].blank?

      system "pg_dump #{args} #{config['database']} > db/structure.sql"
      File.open("#{Rails.root}/db/structure.sql", "a") do |f|
        f << "\n\nSET search_path = public, pg_catalog;\n\n"
        f << ActiveRecord::Base.connection.dump_schema_information
      end
    end
  end
end

# eof