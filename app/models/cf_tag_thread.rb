# -*- encoding: utf-8 -*-

class CfTagThread < ActiveRecord::Base
  self.primary_key = 'tag_thread_id'
  self.table_name  = 'cforum.tags_threads'

  belongs_to :thread, class_name: 'CfThread', :foreign_key => :thread_id
  belongs_to :tag, class_name: 'CfTag', :foreign_key => :tag_id

  attr_accessible :tag_thread_id, :tag_id, :thread_id

  validates_presence_of :tag_id, :thread_id
end

# eof
