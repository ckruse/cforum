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
