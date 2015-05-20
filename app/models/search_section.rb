# -*- coding: utf-8 -*-

class SearchSection < ActiveRecord::Base
  self.primary_key = 'search_section_id'
  self.table_name  = 'search_sections'
end

# eof
