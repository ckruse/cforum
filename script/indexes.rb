#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

begin
  CForum::Thread.ensure_index('message.created_at')
  CForum::Thread.ensure_index('tid')
  CForum::Thread.ensure_index('archived')
rescue
  puts "Error creating views: " + $!.to_s
end
