# -*- encoding: utf-8 -*-

class CfTagThread < ActiveRecord::Base
  self.primary_key = 'tag_thread_id'
  self.table_name  = 'cforum.tags_threads'

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  belongs_to :tag, class_name: 'CfTag', :foreign_key => :tag_id

  attr_accessible :tag_thread_id, :tag_id, :thread_id
end

# eof
