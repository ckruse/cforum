#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), '..', 'lib', 'peon.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'peon', 'grunt.rb')

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new(File.join(File.dirname(__FILE__), '..', 'log', 'grunt.log'))
ActiveRecord::Base.logger = Rails.logger

grunt = Peon::Grunt.instance
grunt.init(['peon'])
grunt.run

# eof
