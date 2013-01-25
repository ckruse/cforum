#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

require 'rake/testtask'

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

namespace :db do |x|
  namespace :structure do |schema|
    schema[:dump].abandon

    task :dump => :environment do
      config = ActiveRecord::Base.configurations[Rails.env]

      args = "-sxO"
      args << ' -h ' + config['host'] unless config['host'].blank?
      args << ' -U ' + config['username'] unless config['username'].blank?

      system "pg_dump #{args} #{config['database']} > db/structure.sql"
      File.open("#{Rails.root}/db/structure.sql", "a") do |f|
        f << ActiveRecord::Base.connection.dump_schema_information
      end
    end
  end
end

Rake::Task['db:create'].enhance do
  ActiveRecord::Base.configurations.each do |name, config|
    begin
      ActiveRecord::Base.establish_connection config
      schema = config['schema_search_path'].split(",").first

      res = ActiveRecord::Base.connection.execute "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '" + schema + "'"
      ActiveRecord::Base.connection.execute "CREATE SCHEMA " + schema if res.ntuples == 0
    rescue
    end
  end
  #Rake::Task['db:after_create'].invoke
end

namespace :test do
  Rake::TestTask.new :plugins do |t|
    t.libs << 'test'
    t.pattern = 'test/plugins/**/*_test.rb'
  end
end

Rake::Task['test:run'].enhance do
  Rake::Task['test:plugins'].invoke
end

# eof
