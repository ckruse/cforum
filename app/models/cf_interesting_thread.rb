# -*- coding: utf-8 -*-

class CfInterestingThread < ActiveRecord::Base
  self.primary_key = 'interesting_thread_id'
  self.table_name  = 'interesting_threads'

  has_one :thread, class: 'CfThread'
end

# eof
