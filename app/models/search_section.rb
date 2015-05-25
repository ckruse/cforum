# -*- coding: utf-8 -*-

class SearchSection < ActiveRecord::Base
  self.primary_key = 'search_section_id'
  self.table_name  = 'search_sections'

  validates_presence_of :name, :position

  belongs_to :forum, class_name: 'CfForum', foreign_key: :forum_id
end

# eof
