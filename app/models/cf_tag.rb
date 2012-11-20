# -*- encoding: utf-8 -*-

class CfTag < ActiveRecord::Base
  self.primary_key = 'tag_id'
  self.table_name  = 'cforum.tags'

  has_many :tags_forums
  has_many :forums, class_name: 'CfForum', :through => :tags_forums

  attr_accessible :tag_id, :tag_name
end

# eof
