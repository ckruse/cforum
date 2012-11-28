# -*- encoding: utf-8 -*-

class CfTag < ActiveRecord::Base
  self.primary_key = 'tag_id'
  self.table_name  = 'cforum.tags'

  has_many :tags_threads
  has_many :threads, class_name: 'CfThread', :through => :tags_threads
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  attr_accessible :tag_id, :tag_name, :forum_id
end

# eof
