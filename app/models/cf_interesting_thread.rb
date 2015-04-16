# -*- coding: utf-8 -*-

class CfInterestingThread < ActiveRecord::Base
  self.primary_key = 'interesting_thread_id'
  self.table_name  = 'interesting_threads'

  belongs_to :thread, class: CfThread
  belongs_to :user, class: CfUser
end

# eof
