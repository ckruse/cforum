#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

CfForum.select('gen_forum_stats(forum_id::integer)').all.to_a
# eof
